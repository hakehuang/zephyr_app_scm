import os
import re
import argparse
import sys

CWD = os.getcwd()

def parse_args():
    parser = argparse.ArgumentParser(
        description="Merge junit files and generate report")
    parser.add_argument('-c', '--commit', default=None,
                        help="Commit being reported.")
    parser.add_argument('-t', '--top', default=None,
                        help="Location of junit files.")
    parser.add_argument('-o', '--output-dir', default=CWD,
                        help="Output directory")

    return parser.parse_args()


def main():
    args = parse_args()

    if not args.top and not args.commit:
        sys.exit("Wrong options")

    for name in os.listdir(args.top):
        if not ".xml" in name:
            continue
        print(name)
        with open(name, "rt") as _f:
            content = _f.read()
            content_new = re.sub(r'classname=".+:', r'classname="', content, flags=re.M)
        with open(name, "wt") as _f:
            _f.write(content_new)

if __name__ == "__main__":
    main()
