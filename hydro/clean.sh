#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for dir in $(find $DIR -maxdepth 2 -mindepth 2 -type d)
do
    rm -rf $dir
done
