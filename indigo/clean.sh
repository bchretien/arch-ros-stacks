#!/bin/sh
# Indigo directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Remove build directories
for dir in $(find ${DIR} -maxdepth 2 -mindepth 2 -type d)
do
  echo "Cleaning ${dir}"
  rm -rI ${dir}
done

# Remove generated packages
for f in $(find ${DIR} -maxdepth 2 -mindepth 2 -type f \
           -name "*.pkg.tar.xz" -or -name "*.src.tar.gz" \
           -or -regextype posix-egrep -regex "${DIR}/.*/[a-zA-Z0-9\_-\.]+\.tar\.gz")
do
  echo "Cleaning ${f}"
  rm -I ${f}
done
