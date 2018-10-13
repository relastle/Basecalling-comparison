'''
Chironでコールできているもののみを所定のフォルダにコピーする。
'''
import shutil


def main() -> None:
    with open('./02_basecalled_reads.tmp/chiron_organized/chiron.fasta') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if i % 2 == 1:
            continue
        fast5_name = line.strip().replace('>', '')
        print(fast5_name)
        shutil.copy(
                './01_raw_fast5.org/{}'.format(fast5_name),
                './01_raw_fast5/{}'.format(fast5_name),
                )
    return


if __name__ == '__main__':
    main()
