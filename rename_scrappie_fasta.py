import argparse


def main() -> None:
    with open(args.path, 'r') as f:
        lines = f.readlines()
    res_lines = []
    for i, line in enumerate(lines):
        if i % 2 == 0:
            space_index = line.index(' ')
            new_line = line[:space_index]
            res_lines.append(new_line)
        else:
            res_lines.append(line.strip())
    for line in res_lines:
        print(line)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("path", type=str)
    args = parser.parse_args()
    main()
