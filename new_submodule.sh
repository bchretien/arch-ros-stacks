#!/bin/sh

function usage() {
  echo "Register submodules created from bare repositories"
  echo ""
  echo "Usage: $0 <relative path from current directory to submodule>"
  echo ""
  echo "Since Git needs a commit id to fully register a submodule, and" \
       "such an id is only available once the first commit is made," \
       "this post-processing step is required when creating a package" \
       "currently unavailable in the AUR."
  echo ""
  echo "Copyright 2015 (c) Benjamin Chrétien <chretien+aur@lirmm.fr>"
  echo "Released under GPL license."
}

function is_submodule()
{
  (git -C $root_dir/$1 rev-parse --is-inside-work-tree) | grep -q true
}

function registerSubmodule() {
  # Check that it is a submodule
  if is_submodule $1; then
    pull_url=$(git -C $root_dir/$1 config --get remote.origin.url)
    push_url=$(git -C $root_dir/$1 config --get remote.origin.pushurl)

    git submodule add ${pull_url} "$1"

    if [[ ! -z "${push_url}" ]]; then
      git -C "$1" remote set-url --push origin ${push_url}
    fi
  fi
}


if [[ -z "$1" ]]; then
  usage
  exit 1
fi

root_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Relative path to submodule from current directory (e.g. indigo/self_test)
SUBMODULE=${1:-}

rel_path=$(python -c "import os.path; print(os.path.relpath('$1', '$root_dir'))")

if [[ -z "${rel_path}" || ! -d "${root_dir}/${rel_path}" ]]; then
  echo "Missing or invalid submodule specified"
  exit 2
fi

pushd "$root_dir"

echo "Registering $rel_path"
registerSubmodule "${rel_path}"

popd
