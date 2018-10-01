from glob import glob
from os.path import basename


def main() -> None:
    fast5_paths = glob('./01_raw_fast5/*.fast5')
    with open('./read_id_to_fast5', 'w') as f:
        for fast5_path in fast5_paths:
            f.write('{}\t{}\n'.format(
                basename(fast5_path),
                basename(fast5_path),
                ))
    return


if __name__ == '__main__':
    main()
