python2 /opt/Chiron/chiron/entry.py \
    call \
    -i ./01_raw_fast5 \
    -o ./02_basecalled_reads.tmp/chiron \
    -m /opt/Chiron/chiron/model/DNA_default \
    --segment_len 400 \
    -t 10 \
    --beam 30
