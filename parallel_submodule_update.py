#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import argparse
import subprocess
from multiprocessing import Pool

# path to the project root
path = os.path.abspath(os.path.dirname(__file__))

def list_submodules():
    gitmodules = open(os.path.join(path, ".gitmodules"), 'r')
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
            return
        except subprocess.CalledProcessError as e:
            # Continue if it's a locking issue
            if b"could not lock config file .git/config: File exists" in e.stderr:
                print("Retrying %s update..." % name)
                continue
            # Rethrow the exception
            else:
                raise e


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update submodules in parallel')
    parser.add_argument(dest="n", nargs='?', const=1, type=int, default=None,
                        help="Number of processes in the process pool")
    args = parser.parse_args()

    p = Pool(args.n)
    p.map(update_submodule, list_submodules())

