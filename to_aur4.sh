#!/bin/sh

# Make sure mksrcinfo is available
command -v mksrcinfo >/dev/null 2>&1 \
  || { echo "Please install pkgbuild-introspection."; exit -1; }

set -e
set -u

# AUR4 parameters
AUR4HOST=${AUR4HOST:-aur4.archlinux.org}
AUR4USER=${AUR4USER:-aur}
AUR4PORT=${AUR4PORT:-22}

# ROS distribution
DISTRIB=${1:-}

# ROS package name (e.g. desktop_full)
LOCAL_NAME=${2:-}

if [[ -z "${DISTRIB}" || -z "${LOCAL_NAME}" ]]; then
  echo "Usage: $0 <ROS distribution> <ROS package name>"
  echo "Example: $0 indigo desktop_full"
  echo "Copyright 2015 (c) Benjamin Chrétien <chretien+aur@lirmm.fr>"
  # TODO: fix license
  echo "Released under dual GPL/BSD license."
  exit 1
fi

if [[ "${DISTRIB}" != "indigo" && "${DISTRIB}" != "jade" ]]; then
  echo "ROS distribution should be \"indigo\" or \"jade\""
  exit 1
fi

# Subdirectory
arch_ros_stacks_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
pushd ${arch_ros_stacks_dir}

subdir="${DISTRIB}/${LOCAL_NAME}"

# Full AUR package name
full_name="ros-${DISTRIB}-${LOCAL_NAME//_/-}"

# Unique branch name for subtree
branch_name="aur4/${full_name}"

# Git repository in the AUR
git_repo="${AUR4USER}@${AUR4HOST}:${AUR4PORT}/${full_name}.git/"

set -x

# Check if the package already exists
if ! $(ssh -p${AUR4PORT} ${AUR4USER}@${AUR4HOST} list-repos | grep -q "${full_name}"); then
  # Create subtree and run mksrcinfo in it
  git subtree split --prefix="${subdir}" -b ${branch_name}
  git filter-branch -f --tree-filter "mksrcinfo" -- ${branch_name}

  # Setup repo if the package does not exist
  ssh -p${AUR4PORT} ${AUR4USER}@${AUR4HOST} setup-repo "${full_name}" || \
    echo "Failed to setup-repo ${full_name}... Maybe it already exists?"

  # Push subtree to AUR4
  git push "ssh+git://${git_repo}" "${branch_name}:master" || \
    echo "git push to ${full_name}.git branch master failed. Maybe repo isn't empty?"

  # Clean branch
  git branch -D ${branch_name}

# If package already exists
else
  # Fetch remote from AUR4
  git fetch "ssh+git://${git_repo}" || \
    echo "git fetch of ${full_name}.git failed. Maybe package doesn't exist?"

  # Pull from AUR4
  # FIXME: leads to merge because of remote .SRCINFO
  #git subtree pull --prefix="${subdir}" "ssh+git://${git_repo}" ${branch_name} || \
  #  echo "git pull of ${full_name}.git failed. Maybe package doesn't exist?"

  # Create subtree and run mksrcinfo in it
  git subtree split --prefix="${subdir}" -b ${branch_name}
  git filter-branch -f --tree-filter "mksrcinfo" -- ${branch_name}

  # Push to AUR4
  git push "ssh+git://${git_repo}" "${branch_name}:master" || \
    echo "git push of ${full_name}.git failed. Maybe package doesn't exist?"

  # Clean branch
  git branch -D ${branch_name}
fi

popd
