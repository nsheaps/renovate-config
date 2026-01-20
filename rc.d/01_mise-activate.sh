#!/usr/bin/env bash

set -euo pipefail

# ensure root_dir is set
: "${DIRENV_ROOT:?Environment variable DIRENV_ROOT must be set}"
# shellcheck source=../bin/lib/stdlib.sh
source "${DIRENV_ROOT}"/bin/lib/stdlib.sh

cd "${DIRENV_ROOT}"

# activate mise environment
# check to see that mise is installed.
if command -v mise &> /dev/null; then

    # if not installed via a package manager, having an out of date
    # version of mise can result in strange errors when installing node due to gpg
    # signing, so we'll just eat the error
    mise self-update >/dev/null 2>&1 || true
    mise trust --quiet
    mise install -y

    # activate mise in the current shell
    eval "$(mise activate bash)"
else
    # mise is not installed, error and exit
    echo "Error: mise is not installed. Please install mise to proceed."
    echo "   see : https://mise.jdx.dev/cli/install.html"
    exit 1
fi

# enable and install corepack for yarn
corepack enable
corepack install

watch_file "${DIRENV_ROOT}/.mise.toml"
