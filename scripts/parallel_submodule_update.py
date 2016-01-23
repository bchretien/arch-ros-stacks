#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import re
import argparse
import subprocess
from multiprocessing import Pool

# path to the project root
path = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))

def list_submodules(distrib):
    gitmodules = open(os.path.join(path, ".gitmodules"), 'r')
    if distrib:
        matches = re.findall("path = (%s/[\w\-_\/]+)" % distrib, gitmodules.read())
    else:
        matches = re.findall("path = ([\w\-_\/]+)", gitmodules.read())
    gitmodules.close()
    return matches


def update_submodule(name):
    cmd = ["git", "-C", path, "submodule", "update", "--init", name]
    print("Updating %s..." % name)
    # The init locks .git/config, so it may conflict with another process.
    # We will retry until it succeeds
    while True:
        try:
            subprocess.check_output(cmd, stderr=subprocess.PIPE, shell=False)
            print("%s updated" % name)
            return None
        except subprocess.CalledProcessError as e:
            # Continue if it's a locking issue
            if b"could not lock config file .git/config: File exists" in e.stderr:
                print("Retrying %s update..." % name)
                continue
            # Rethrow the exception
            else:
                print(e.stderr.decode("utf-8"), file=sys.stderr)
                return name


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update submodules in parallel')
    parser.add_argument(dest="n", nargs='?', const=1, type=int, default=None,
                        help="Number of processes in the process pool")
    parser.add_argument("-d", dest="distrib", nargs='?', const=1, type=str, default=None,
                        help="ROS distribution (e.g. indigo)")
    args = parser.parse_args()

    if args.distrib and not args.distrib in ["indigo", "jade"]:
        print("Invalid ROS distribution given", file=sys.stderr)
        sys.exit(1)

    p = Pool(args.n)
    submodules_status = p.map(update_submodule,
                              list_submodules(args.distrib))
    failed_submodules = list(filter(None.__ne__, submodules_status))
    if len(failed_submodules) > 0:
        print("Following submodules have not been updated:\n  - ", end="")
        print(*failed_submodules, sep='\n  - ')
        sys.exit(2)

