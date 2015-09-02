#!/usr/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd ${DIR}

# For each Git submodule
git submodule --quiet foreach "
  # If it's an AUR submodule with an HTTPS URL
  pull_url=\$(git config --get remote.origin.url)
  package_name=\$(echo \${pull_url} | sed -n 's;https://aur.archlinux.org/\([-A-Za-z0-9]\+\);\1;p')
  if [[ ! -z \${package_name} ]]; then
    echo \"Setting push URL for \${path}\"

    # Set the push URL to ssh+git
    push_url=\"ssh+git://aur@aur.archlinux.org/\${package_name}\"
    git -C \"$DIR/\${path}\" remote set-url --push origin \${push_url}
  fi
"

popd
