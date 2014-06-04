#!/bin/sh
# Indigo directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Remove build directories
for dir in $(find $DIR -maxdepth 2 -mindepth 2 -type d)
do
    rm -rf $dir
done

# Remove generated packages
for f in $(find $DIR -maxdepth 2 -mindepth 2 -type f \
           -name "*.pkg.tar.xz" -or -name "*.src.tar.gz")
do
    rm $f
done
