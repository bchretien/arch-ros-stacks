#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <stack-directory|PKGBUILD>"
    exit 1
fi

if [ -d "$1" ] && [ -f "$1/PKGBUILD" ]; then
    . $1/PKGBUILD
elif [ -f "$1" ]; then
    . $1
else
    echo "Unable to open PKGBUILD for '$1'."
    exit 1
fi

echo ${ros_depends}
