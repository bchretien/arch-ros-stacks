#!/bin/sh
# Indigo directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Reset submodules
for dir in $(git status --porcelain ${DIR} | grep "^ M " | cut -d' ' -f3)
do
  echo "Resetting ${dir}..."
  cd "${DIR}/$(basename ${dir})" && git reset --hard origin/master --
done
