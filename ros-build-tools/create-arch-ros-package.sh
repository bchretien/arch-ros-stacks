#!/bin/bash

if [ -z "$4" ]; then
    echo "Usage: $0 <distro> <stack> <version> <stack-url>"
    exit 1
fi

DISTRO=$1
STACK=$2
PACKAGE=$(echo $STACK | sed 's/_/-/g')
VERSION=$3
URL=$4

PACKAGE_DIRECTORY=$(pwd)

read -p "Create package for stack $STACK in directory $PACKAGE_DIRECTORY? (y/n) "
if ![ "$REPLY" == "y" ]; then
    exit 0
fi

TMP_STACK_NAME=$(mktemp stack-XXXXXXXXXX)
wget "$URL" -O $TMP_STACK_NAME
MD5=$(md5sum $TMP_STACK_NAME | awk '{print $1}')
rm $TMP_STACK_NAME

cp /usr/share/ros-build-tools/PKGBUILD.rostemplate $PACKAGE_DIRECTORY/PKGBUILD

sed -i "s/@PACKAGE_NAME@/$PACKAGE/g" $PACKAGE_DIRECTORY/PKGBUILD
sed -i "s/@STACK_NAME@/$STACK/g" $PACKAGE_DIRECTORY/PKGBUILD
sed -i "s/@STACK_VERSION@/$VERSION/g" $PACKAGE_DIRECTORY/PKGBUILD
sed -i "s?@STACK_URL@?$URL?g" $PACKAGE_DIRECTORY/PKGBUILD
sed -i "s/@STACK_MD5@/$MD5/g" $PACKAGE_DIRECTORY/PKGBUILD
sed -i "s/@ROS_DISTRO@/$DISTRO/g" $PACKAGE_DIRECTORY/PKGBUILD

echo "PKGBUILD created for stack $STACK."
echo ""
echo "Fill in dependencies and the stack description."
echo "If the stack contains python scripts, consider running fix-python-scripts.sh."
