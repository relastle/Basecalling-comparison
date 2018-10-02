#!/usr/bin/env bash

# Copyright 2017 Ryan Wick (rrwick@gmail.com)
# https://github.com/rrwick/Basecalling-comparison

# This program is free software: you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version. This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You
# should have received a copy of the GNU General Public License along with this program. If not,
# see <http://www.gnu.org/licenses/>.

# This script conducts read and assembly analysis on a set of ONT reads, comparing them to a
# reference sequence. It expects to find the following in the directory where it's run:
#   * reference.fasta: the reference sequence
#   * 01_raw_fast5 directory: has all fast5 files
#   * 02_basecalled_reads directory: has one or more fastq.gz/fasta.gz read files
#   * read_id_to_fast5: a file with two columns: read_ID and fast5 filename
#   * illumina_1.fastq.gz illumina_2.fastq.gz: Illumina reads for the same sample

# Set this to the desired number of threads (for alignment and polishing).
threads=10

# Set this to the directory containing the Python scripts (e.g. read_length_identity.py).
python_script_dir=./

# Set the full path to Nanopolish here.
nanopolish_exec_dir=/opt/nanopolish

# Set the paths to Medaka and Pomoxis venv activate files
medaka=${MEDAKA_ACTIVATION_PATH}
pomoxis=${POMOXIS_ACTIVATION_PATH}

illumina_1=./data/illumina/illumina_1.fastq.gz
illumina_2=./data/illumina/illumina_2.fastq.gz

reference=./data/barcode/reference.fasta

# If you want to run this script on all read files in the 02_basecalled_reads directory, leave
# these lines uncommented:
cd 02_basecalled_reads
read_files=$(ls)
cd ..

# If you want to run this script only on particular read files, change and uncomment this line:
# read_files="albacore_v0.8.4.fastq.gz"

# Make necessary directories.
mkdir -p 03_read_names_fixed
mkdir -p 04_read_data
mkdir -p 05_trimmed_reads
mkdir -p 06_subsampled_reads
mkdir -p 07_assemblies
mkdir -p 08_assembly_data
mkdir -p 09_nanopolish
mkdir -p 10_nanopolish_data
mkdir -p 11_nanopolish_meth
mkdir -p 12_nanopolish_meth_data
mkdir -p 13_medaka
mkdir -p 14_medaka_data
mkdir -p 15_combined_polish
mkdir -p 16_combined_polish_data

# Create a table of basic info about each read.
python3 "$python_script_dir"/read_table.py 01_raw_fast5 > 04_read_data/read_data.tsv

for f in $read_files; do
    # 末尾のfastq.gzかfasta.gz削除
    set=${f%.fastq.gz}
    set=${set%.fasta.gz}

    # Save file paths in variables, for brevity.
    raw_fast5_dir=01_raw_fast5
    all_reads=02_basecalled_reads/"$f"
    all_reads_fixed_names=03_read_names_fixed/"$f"
    read_alignment=04_read_data/"$set".paf
    read_data=04_read_data/"$set"_reads.tsv
    trimmed_reads=05_trimmed_reads/"$set".fastq.gz
    subsampled_reads=06_subsampled_reads/"$set".fastq.gz

    assembly=07_assemblies/"$set"_assembly.fasta
    assembly_pieces=08_assembly_data/"$set"_assembly_pieces.fasta
    assembly_alignment=08_assembly_data/"$set"_assembly.paf
    assembly_data=08_assembly_data/"$set"_assembly.tsv

    nanopolish_assembly_dir=09_nanopolish
    nanopolish_assembly=09_nanopolish/"$set"_nanopolish.fasta
    nanopolish_assembly_pieces=10_nanopolish_data/"$set"_nanopolish_pieces.fasta
    nanopolish_assembly_alignment=10_nanopolish_data/"$set"_nanopolish.paf
    nanopolish_assembly_data=10_nanopolish_data/"$set"_nanopolish.tsv

    nanopolish_meth_assembly_dir=11_nanopolish_meth
    nanopolish_meth_assembly=11_nanopolish_meth/"$set"_nanopolish_meth.fasta
    nanopolish_meth_assembly_pieces=12_nanopolish_meth_data/"$set"_nanopolish_meth_pieces.fasta
    nanopolish_meth_assembly_alignment=12_nanopolish_meth_data/"$set"_nanopolish_meth.paf
    nanopolish_meth_assembly_data=12_nanopolish_meth_data/"$set"_nanopolish_meth.tsv

    medaka_assembly_dir=13_medaka
    medaka_assembly=13_medaka/"$set"_medaka.fasta
    medaka_assembly_pieces=14_medaka_data/"$set"_medaka_pieces.fasta
    medaka_assembly_alignment=14_medaka_data/"$set"_medaka.paf
    medaka_assembly_data=14_medaka_data/"$set"_medaka.tsv

    medaka_nanopolish_assembly_dir=15_combined_polish
    medaka_nanopolish_assembly=15_combined_polish/"$set"_medaka_nanopolish_meth.fasta
    medaka_nanopolish_assembly_pieces=16_combined_polish_data/"$set"_medaka_nanopolish_meth_pieces.fasta
    medaka_nanopolish_assembly_alignment=16_combined_polish_data/"$set"_medaka_nanopolish_meth.paf
    medaka_nanopolish_assembly_data=16_combined_polish_data/"$set"_medaka_nanopolish_meth.tsv

    nanopolish_medaka_assembly_dir=15_combined_polish
    nanopolish_medaka_assembly=15_combined_polish/"$set"_nanopolish_meth_medaka.fasta
    nanopolish_medaka_assembly_pieces=16_combined_polish_data/"$set"_nanopolish_meth_medaka_pieces.fasta
    nanopolish_medaka_assembly_alignment=16_combined_polish_data/"$set"_nanopolish_meth_medaka.paf
    nanopolish_medaka_assembly_data=16_combined_polish_data/"$set"_nanopolish_meth_medaka.tsv

    printf "\n\n\n\n"
    echo "NORMALISE READ HEADERS: "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/fix_read_names.py $all_reads read_id_to_fast5 | gzip > $all_reads_fixed_names

    printf "\n\n\n\n"
    echo "ASSESS READS: "$set
    echo "--------------------------------------------------------------------------------"
    minimap2 -k12 -t $threads -c ${reference} $all_reads_fixed_names > $read_alignment
    python3 "$python_script_dir"/read_length_identity.py $all_reads_fixed_names $read_alignment > $read_data
    rm $read_alignment

    printf "\n\n\n\n"
    echo "ASSEMBLY: "$set
    echo "--------------------------------------------------------------------------------"
    porechop -i $all_reads_fixed_names -o $trimmed_reads --no_split --threads $threads --check_reads 1000
    filtlong -1 ${illumina_1} -2 ${illumina_2} --min_length 1000 --target_bases 500000000 --trim --split 250 $trimmed_reads | gzip > $subsampled_reads
    rebaler -t $threads ${reference} $subsampled_reads > $assembly

    printf "\n\n\n\n"
    echo "ASSESS ASSEMBLY: "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/chop_up_assembly.py $assembly 10000 > $assembly_pieces
    minimap2 -k12 -t $threads -c ${reference} $assembly_pieces > $assembly_alignment
    python3 "$python_script_dir"/read_length_identity.py $assembly_pieces $assembly_alignment > $assembly_data
    rm $assembly_pieces $assembly_alignment

    printf "\n\n\n\n"
    echo "NANOPOLISH: "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/nanopolish_slurm_wrapper.py $assembly $all_reads_fixed_names $raw_fast5_dir $nanopolish_assembly_dir $nanopolish_exec_dir $threads
    rm "$all_reads_fixed_names".index*
    rm "$assembly".fai

    printf "\n\n\n\n"
    echo "ASSESS NANOPOLISHED ASSEMBLY: "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/chop_up_assembly.py $nanopolish_assembly 10000 > $nanopolish_assembly_pieces
    minimap2 -x map10k -t $threads -c ${reference} $nanopolish_assembly_pieces > $nanopolish_assembly_alignment
    python3 "$python_script_dir"/read_length_identity.py $nanopolish_assembly_pieces $nanopolish_assembly_alignment > $nanopolish_assembly_data
    rm $nanopolish_assembly_pieces $nanopolish_assembly_alignment

    printf "\n\n\n\n"
    echo "NANOPOLISH (METHYLATION-AWARE): "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/nanopolish_slurm_wrapper.py $assembly $all_reads_fixed_names $raw_fast5_dir $nanopolish_meth_assembly_dir $nanopolish_exec_dir $threads meth
    rm "$all_reads_fixed_names".index*
    rm "$assembly".fai

    printf "\n\n\n\n"
    echo "ASSESS NANOPOLISHED (METHYLATION-AWARE) ASSEMBLY: "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/chop_up_assembly.py $nanopolish_meth_assembly 10000 > $nanopolish_meth_assembly_pieces
    minimap2 -x map10k -t $threads -c ${reference} $nanopolish_meth_assembly_pieces > $nanopolish_meth_assembly_alignment
    python3 "$python_script_dir"/read_length_identity.py $nanopolish_meth_assembly_pieces $nanopolish_meth_assembly_alignment > $nanopolish_meth_assembly_data
    rm $nanopolish_meth_assembly_pieces $nanopolish_meth_assembly_alignment

    printf "\n\n\n\n"
    echo "MEDAKA: "$set
    echo "--------------------------------------------------------------------------------"
    if [[ $all_reads_fixed_names = *"fastq.gz" ]]; then
        temp_reads="$medaka_assembly_dir"/"$set".fastq
    else
        temp_reads="$medaka_assembly_dir"/"$set".fasta
    fi
    gunzip -c "$all_reads_fixed_names" > $temp_reads
    source $medaka
    medaka_consensus -i $temp_reads -d $assembly -o "$medaka_assembly_dir"/"$set"_medaka -p $pomoxis -t $threads
    deactivate
    cp "$medaka_assembly_dir"/"$set"_medaka/consensus.fasta "$medaka_assembly"
    rm $temp_reads
    rm -r "$medaka_assembly_dir"/"$set"_medaka

    printf "\n\n\n\n"
    echo "ASSESS MEDAKA ASSEMBLY: "$set
    echo "--------------------------------------------------------------------------------"
    python3 "$python_script_dir"/chop_up_assembly.py $medaka_assembly 10000 > $medaka_assembly_pieces
    minimap2 -x map10k -t $threads -c ${reference} $medaka_assembly_pieces > $medaka_assembly_alignment
    python3 "$python_script_dir"/read_length_identity.py $medaka_assembly_pieces $medaka_assembly_alignment > $medaka_assembly_data
    rm $medaka_assembly_pieces $medaka_assembly_alignment

    # printf "\n\n\n\n"
    # echo "NANOPOLISH (METHYLATION-AWARE) OF MEDAKA ASSEMBLY: "$set
    # echo "--------------------------------------------------------------------------------"
    # python3 "$python_script_dir"/nanopolish_slurm_wrapper.py $medaka_assembly $all_reads_fixed_names $raw_fast5_dir $medaka_nanopolish_assembly_dir $nanopolish_exec_dir $threads meth
    # rm "$all_reads_fixed_names".index*
    # rm "$medaka_assembly".fai

    # printf "\n\n\n\n"
    # echo "ASSESS MEDAKA THEN NANOPOLISH (METHYLATION-AWARE) ASSEMBLY: "$set
    # echo "--------------------------------------------------------------------------------"
    # python3 "$python_script_dir"/chop_up_assembly.py $medaka_nanopolish_assembly 10000 > $medaka_nanopolish_assembly_pieces
    # minimap2 -x map10k -t $threads -c ${reference} $medaka_nanopolish_assembly_pieces > $medaka_nanopolish_assembly_alignment
    # python3 "$python_script_dir"/read_length_identity.py $medaka_nanopolish_assembly_pieces $medaka_nanopolish_assembly_alignment > $medaka_nanopolish_assembly_data
    # rm $medaka_nanopolish_assembly_pieces $medaka_nanopolish_assembly_alignment

    # printf "\n\n\n\n"
    # echo "MEDAKA OF NANOPOLISH (METHYLATION-AWARE) ASSEMBLY: "$set
    # echo "--------------------------------------------------------------------------------"
    # if [[ $all_reads_fixed_names = *"fastq.gz" ]]; then
    #     temp_reads="$nanopolish_medaka_assembly_dir"/"$set".fastq
    # else
    #     temp_reads="$nanopolish_medaka_assembly_dir"/"$set".fasta
    # fi
    # gunzip -c "$all_reads_fixed_names" > $temp_reads
    # source $medaka
    # medaka_consensus -i $temp_reads -d $assembly -o "$nanopolish_medaka_assembly_dir"/"$set"_nanopolish_medaka -p $pomoxis -t $threads
    # deactivate
    # cp "$nanopolish_medaka_assembly_dir"/"$set"_nanopolish_medaka/consensus.fasta "$nanopolish_medaka_assembly"
    # rm $temp_reads
    # rm -r "$nanopolish_medaka_assembly_dir"/"$set"_nanopolish_medaka

    # printf "\n\n\n\n"
    # echo "ASSESS MEDAKA ASSEMBLY: "$set
    # echo "--------------------------------------------------------------------------------"
    # python3 "$python_script_dir"/chop_up_assembly.py $nanopolish_medaka_assembly 10000 > $nanopolish_medaka_assembly_pieces
    # minimap2 -x map10k -t $threads -c ${reference} $nanopolish_medaka_assembly_pieces > $nanopolish_medaka_assembly_alignment
    # python3 "$python_script_dir"/read_length_identity.py $nanopolish_medaka_assembly_pieces $nanopolish_medaka_assembly_alignment > $nanopolish_medaka_assembly_data
    # rm $nanopolish_medaka_assembly_pieces $nanopolish_medaka_assembly_alignment

done
