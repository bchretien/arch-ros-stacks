#!/bin/sh

function processPackage() {
  local distro=$1
  local local_name=$2

  # Full AUR package name
  full_name="ros-${distro}-${local_name//_/-}"
  url_ro="https://aur.archlinux.org/${full_name}.git"
  url_rw="ssh+git://aur@aur.archlinux.org/${full_name}.git"
  rel_package_dir="${root_dir}/${local_name}"
  package_dir="${distro}/${local_name}"

  if [[ ! -d "${package_dir}" ]]; then
    echo "Package ${package_dir} does not exist"
    return
  fi

  if [[ -f "${package_dir}/.git" ]]; then
    echo "Package ${package_dir} is already a submodule"
    return
  fi

  remote_exists=`git ls-remote --exit-code -h "${url_ro}"`
  if [[ -z "${remote_exists}" ]]; then
    echo "${full_name} not available in the AUR"
    return
  fi

  mkdir -p "${distro}_backup"

  git mv "${package_dir}" "${distro}_backup/${local_name}"
  git submodule add "${url_ro}" "${package_dir}"
  git -C "${package_dir}" remote set-url --push origin "${url_rw}"
}


root_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
pushd ${root_dir}

# Make sure mksrcinfo is available
command -v mksrcinfo >/dev/null 2>&1 \
  || { echo "Please install pkgbuild-introspection."; exit -1; }

# AUR4 parameters
AUR4HOST=${AUR4HOST:-aur.archlinux.org}
AUR4USER=${AUR4USER:-aur}
AUR4PORT=${AUR4PORT:-22}

# Query or ROS distribution
DISTRO=${1:-}

# ROS package name (e.g. desktop_full)
LOCAL_NAME=${2:-}

if [[ "${DISTRO}" != "indigo" && "${DISTRO}" != "jade" ]]; then
  echo "Invalid ROS distribution"
  exit 2
fi

if [[ -z "${LOCAL_NAME}" ]]; then
  # For each package of the distro
  packages=`find ${DISTRO} -maxdepth 1 -mindepth 1 -type d`
  for p in ${packages}; do
    processPackage ${DISTRO} ${p##*/}
  done
else
  processPackage ${DISTRO} ${LOCAL_NAME}
fi

popd
