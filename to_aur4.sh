#!/bin/sh

function usage() {
  echo "Push ROS-related package modifications to the AUR (v4)"
  echo ""
  echo "Usage 1: push a specific ROS package for a given ROS" \
       "distribution"
  echo ""
  echo "  Command: $0 <ROS distribution> <ROS package name>"
  echo "  Example: $0 indigo desktop_full"
  echo ""
  echo ""
  echo "Usage 2: push a specific ROS dependency package"
  echo ""
  echo "  Command: $0 dependency <package name>"
  echo "  Example: $0 dependency python2-empy"
  echo ""
  echo ""
  echo "Usage 3: push the packages from the last commit"
  echo ""
  echo "  Command: $0 commit"
  echo ""
  echo "Copyright 2015 (c) Benjamin Chrétien <chretien+aur@lirmm.fr>"
  echo "Released under GPL license."
}


function newPackage() {
  local package_dir=$1
  local package_name=$2
  local branch_name=$3
  local git_repo=$4

  # Create subtree and run mksrcinfo in it
  git subtree split --prefix="${package_dir}" -b ${branch_name}
  squashCheck ${package_name} ${branch_name}

  git stash -q
  git filter-branch -f --tree-filter "mksrcinfo" -- ${branch_name}
  git stash pop -q &>/dev/null

  # Setup repo if the package does not exist
  ssh -p${AUR4PORT} ${AUR4USER}@${AUR4HOST} setup-repo "${package_name}" || \
    echo "Failed to setup-repo ${package_name}... Maybe it already exists?"

  # Push subtree to AUR4
  git push "ssh+git://${git_repo}" "${branch_name}:master" || \
    echo "git push to ${package_name}.git branch master failed. Maybe repo isn't empty?"

  # Clean branch
  git branch -D ${branch_name}
}

function updatePackage() {
  local package_dir=$1
  local package_name=$2
  local branch_name=$3
  local git_repo=$4

  # Fetch remote from AUR4
  git fetch "ssh+git://${git_repo}" || \
    echo "git fetch of ${package_name}.git failed. Maybe package doesn't exist?"

  # Pull from AUR4
  # FIXME: leads to merge because of remote .SRCINFO
  #git subtree pull --prefix="${subdir}" "ssh+git://${git_repo}" ${branch_name} || \
  #  echo "git pull of ${full_name}.git failed. Maybe package doesn't exist?"

  # Create subtree and run mksrcinfo in it
  git subtree split --prefix="${package_dir}" -b ${branch_name}
  squashCheck ${package_name} ${branch_name}
  git stash -q
  git filter-branch -f --tree-filter "mksrcinfo" -- ${branch_name}
  git stash pop -q &>/dev/null

  # Push to AUR4
  git push "ssh+git://${git_repo}" "${branch_name}:master" || \
    echo "git push of ${package_name}.git failed. Maybe package doesn't exist?"

  # Clean branch
  git branch -D ${branch_name}
}

function processPackage() {
  local package_dir=$1
  local package_name=$2

  # Unique branch name for subtree
  local branch_name="aur4/${package_name}"

  # Git repository in the AUR
  local git_repo="${AUR4USER}@${AUR4HOST}:${AUR4PORT}/${package_name}.git/"

  # Check that a PKGBUILD exists
  if [ ! -f "${package_dir}/PKGBUILD" ]; then
    echo "PKGBUILD not found in ${package_dir}"
    return
  fi

  # Check if the package already exists
  if ! $(ssh -p${AUR4PORT} ${AUR4USER}@${AUR4HOST} list-repos | \
         grep -q "${package_name}"); then
    # Create new AUR package
    newPackage "$@" ${branch_name} ${git_repo}
  else
    # Update existing AUR package
    updatePackage "$@" ${branch_name} ${git_repo}
  fi
}

# Some PKGBUILDs were not valid when added to arch-ros-stacks (*cough*
# ros-build-tools *cough*), so our git filter-branch here will lead to invalid
# .AURINFO and a rejected push from the AUR. For now, we'll squash commits
# until the first valid one before pushing. In order to be able to update the
# AUR package with this script, DO NOT CHANGE THE COMMIT HASHES SET HERE!
function squashCheck() {
  local package=$1
  local branch=$2
  if [[ "${package}" == "ros-build-tools" ]]; then
    squashHead ${branch} c8aba9f523731dc2f7623417faf60e8a308c6a5f
  fi
}

# Function inspired from: http://stackoverflow.com/a/436530/1043187
function squashHead() {
  local branch=$1
  local good_sha=$2

  local first_sha=$(git rev-list --max-parents=0 ${branch})

  local master_branch=$(git rev-parse --abbrev-ref HEAD)

  git stash -q
  git checkout ${branch}

  # Go back to the last commit that we want
  # to form the initial commit (detach HEAD)
  git checkout ${good_sha}

  # reset the branch pointer to the initial commit,
  # but leaving the index and working tree intact.
  git reset --soft ${first_sha}

  # amend the initial tree using the tree from 'B'
  git commit --amend -m "Squashed commits"

  # temporarily tag this new initial commit
  # (or you could remember the new commit sha1 manually)
  git tag -f tmp

  # go back to the original branch (assume master for this example)
  git checkout ${branch}

  # Replay all the commits after B onto the new initial commit
  git rebase --no-verify --onto tmp ${good_sha}

  # remove the temporary tag
  git tag -d tmp

  git checkout ${master_branch}
  git stash pop -q &>/dev/null
}

# Make sure mksrcinfo is available
command -v mksrcinfo >/dev/null 2>&1 \
  || { echo "Please install pkgbuild-introspection."; exit -1; }

set -e
set -u

# AUR4 parameters
AUR4HOST=${AUR4HOST:-aur4.archlinux.org}
AUR4USER=${AUR4USER:-aur}
AUR4PORT=${AUR4PORT:-22}

# Query or ROS distribution
USER_QUERY=${1:-}

# ROS package name (e.g. desktop_full)
LOCAL_NAME=${2:-}

if [[ "${USER_QUERY}" == "dependency" ]]; then
  query_type="dependency"
elif [[ "${USER_QUERY}" == "commit" ]]; then
  query_type="commit"
elif [[ "${USER_QUERY}" == "indigo" || "${USER_QUERY}" == "jade" ]]; then
  query_type="ros"
else
  usage
  exit 1
fi

if [[ "${query_type}" != "commit" && -z "${LOCAL_NAME}" ]]; then
  usage
  exit 1
fi

# arch-ros-stacks directory
arch_ros_stacks_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
pushd ${arch_ros_stacks_dir}

set -x

if [[ "${query_type}" == "ros" ]]; then
  # ROS distribution
  distrib=${USER_QUERY}

  # Subdirectory in arch-ros-stacks
  subdir="${distrib}/${LOCAL_NAME}"

  # Full AUR package name
  full_name="ros-${distrib}-${LOCAL_NAME//_/-}"

  # Process package
  processPackage ${subdir} ${full_name}
elif [[ "${query_type}" == "dependency" ]]; then
  # Subdirectory in arch-ros-stacks
  subdir="dependencies/${LOCAL_NAME}"

  # Full AUR package name
  full_name="${LOCAL_NAME}"

  # Process package
  processPackage ${subdir} ${full_name}
elif [[ "${query_type}" == "commit" ]]; then
  updated_pkgbuilds=$(git diff-tree --no-commit-id --name-only -r HEAD | grep PKGBUILD)
  for p in ${updated_pkgbuilds}; do
    # If the PKGBUILD does not exist (e.g. was removed in the commit)
    if [[ ! -f "${p}" ]]; then
      break
    fi

    subdir=$(dirname ${p})
    first_subdir=${subdir%/*}
    if [[ "${first_subdir}" == "dependencies" ]]; then
      full_name=$(basename ${subdir})
    elif [[ "${first_subdir}" == "indigo" || \
            "${first_subdir}" == "jade" ]]; then
      raw_name=$(basename ${subdir})
      full_name="ros-${first_subdir}-${raw_name//_/-}"
    fi

    # Process package
    processPackage ${subdir} ${full_name}
  done
fi

popd
