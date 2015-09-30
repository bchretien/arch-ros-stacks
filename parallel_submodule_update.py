#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
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
    res = subprocess.call(cmd, shell=False, stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL)
    print("%s updated" % name)
    return res


if __name__ == '__main__':
    p = Pool()
    p.map(update_submodule, list_submodules())

