'''
Get intersection of input fasta files by their IDs
'''

import sys
import argparse
from glob import glob
import os
from typing import Any, List  # noqa

sys.path.append('../Halcyon/scripts/ml/input_data')

from fasta_fetcher import (  # noqa
        FastaFetcher,
        FastaFetcherGroundTruth,
        FastaFetcherScrappie,
        )


def check_has_key(
        k: str,
        fetchers: List[FastaFetcher],
        ) -> List[str]:
    res = []  # type: List[str]
    for f in fetchers:
        seq = f.fetch(k)
        if seq == '':
            return []
        res.append(seq)
    return res


def main() -> None:
    os.makedirs(args.output_dir, exist_ok=True)
    fasta_paths = glob(os.path.join(
        args.input_dir,
        '*.fasta',
        ))
    fetchers = []  # type: List[FastaFetcher]
    for path in fasta_paths:
        fetchers.append(FastaFetcherGroundTruth(path))
    print(fetchers)

    fasta_liens_lst = [
            [] for i in range(len(fetchers))
            ]  # type: List[List[str]]

    base_fetcher = fetchers[0]
    for i, (k, v) in enumerate(base_fetcher.get_item_dict().items()):
        seqs = check_has_key(k, fetchers)
        if len(seqs) == 0:
            continue
        for i, seq in enumerate(seqs):
            fasta_liens_lst[i].append('>{}'.format(k))
            fasta_liens_lst[i].append(seq)
    for i, fasta_path in enumerate(fasta_paths):
        fasta_name = os.path.basename(fasta_path)
        with open(os.path.join(args.output_dir, fasta_name), 'w') as f:
            for line in fasta_liens_lst[i]:
                f.write(line+'\n')
    return


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '-i', '--input_dir',
            type=str,
            required=True,
            )
    parser.add_argument(
            '-o', '--output_dir',
            type=str,
            required=True,
            )
    args = parser.parse_args()
    main()
