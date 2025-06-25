#!/usr/bin/env bash

# exit on error/unsetvar/pipefail
set -euo pipefail

# shellcheck source=../bin/lib/stdlib.sh
source "${DIRENV_ROOT}/bin/lib/stdlib.sh"

# https://direnv.net/man/direnv-stdlib.1.html
# These functions are only available during direnv execution
# This special function tells direnv to watch this file and reload if it changes (on next prompt)
watch_file "${DIRENV_ROOT}/.nvmrc"

# The way we use .nvmrc we could probably check to see if node -v matches the nvmrc
# and skip this altogether if it does. But there's some nuanced details around version matching
# with things like a v prefix, so for now we'll just always run this. Running nvm adds about 500ms
# to the run so it's noticable, but only when CDing into the directory, and it saves us more time
# later from having to deal with "oh I forgot to switch to the right node version" issues.

SKIP_NVM_INIT=${SKIP_NVM_INIT:-}
if [[ -n "${SKIP_NVM_INIT}" ]]; then
  if_debug echo "Skipping nvm init"
  return
fi

# Direnv can use a version of node without nvm being involved
# so if it's available, load it from nvm
# docs: https://direnv.net/man/direnv-stdlib.1.html#codeuse-node-ltversiongtcode
export NVM_DIR="$HOME/.nvm"
export NODE_VERSION_PREFIX=v
export NODE_VERSIONS="$NVM_DIR/versions/node"
if use node "$(cat "${DIRENV_ROOT}/.nvmrc")"; then
  # check to see if corepack is enabled and using the correct package manager version
  NODE_DIRECTORY=$(dirname "$(which node)")
  if [[ ! -f "${NODE_DIRECTORY}/yarn" ]]; then
    # yarn isn't linked in the bin directory for this version of node
    warn "yarn is not linked for node version $(cat "${DIRENV_ROOT}/.nvmrc")"
    debug "asking corepack to install the listed packageManager and enabling corepack"
    "$ROOT_DIR/bin/corepack-setup"
    if_debug debug "yarn: $(which yarn) -> $(realpath "$(which yarn)")"
  else
    # yarn is linked, but we should check that it's from corepack by looking
    # at the symlink target
    YARN_SYMLINK_TARGET=$(readlink -f "${NODE_DIRECTORY}/yarn")
    if [[ "${YARN_SYMLINK_TARGET}" != */corepack/* ]]; then
      warn "yarn was found at ${NODE_DIRECTORY}/yarn but isn't from corepack"
      debug "yarn symlink target: ${YARN_SYMLINK_TARGET}"

      # yarn is linked, but it's not from corepack
      debug "asking corepack to install the listed packageManager and enabling corepack"
      "$ROOT_DIR/bin/corepack-setup"
      if_debug debug "yarn: $(which yarn) -> $(realpath "$(which yarn)")"
    fi
    # technically there is a case where the version is wrong, but let's not address
    # that for now since all of this is trying to only add execution time if the symlinks
    # are wrong (so most cases this shouldn't actually run)
  fi
  return
else
  echo "Installing node version $(cat "${DIRENV_ROOT}/.nvmrc") via nvm"
fi

if command -v nvm >/dev/null 2>&1; then
  # for some reason this never seems to happen, the
  # shell alias is lost in the context of direnv loading
  # even if available after direnv has done it's thing.
  # Since we only use nvm to install node, we abort
  # loading nvm above
  if_debug echo "nvm is already loaded"
else
  if_debug echo "Loading nvm"

  # We have to load nvm manually because its not passed to direnv.

  # shellcheck disable=SC1091 # Can't load $HOME/.nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" --no-use
  # shellcheck disable=SC1091 # Can't load $HOME/.nvm
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
fi

# uses find_up from direnv stdlib: https://direnv.net/man/direnv-stdlib.1.html#codefindup-ltfilenamegtcode
nvm_path="$(find_up .nvmrc | command tr -d '\n' | xargs dirname)"

declare nvm_version
nvm_version=$(<"${nvm_path}"/.nvmrc)

declare locally_resolved_nvm_version
# `nvm ls` will check all locally-available versions
# If there are multiple matching versions, take the latest one
# Remove the `->` and `*` characters and spaces
# `locally_resolved_nvm_version` will be `N/A` if no local versions are found
{
  # pipefail is expected here due to the chain of commands. The {} ensures the pipefail only applies to this command
  set +o pipefail
  locally_resolved_nvm_version="$(nvm ls --no-colors "${nvm_version}" | command tail -1 | command tr -d '\->*' | command tr -d '[:space:]')"
}

# If it is not already installed, install it
# `nvm install` will implicitly use the newly-installed version
if [[ "${locally_resolved_nvm_version}" = 'N/A' ]]; then
  if_debug echo "Installing node version ${nvm_version}"

  nvm install "${nvm_version}"

  # make sure corepack is enabled and using the correct package manager version
  corepack enable
  corepack install
  if_debug echo "node: $(node -v) (from $(ls -lha "$(which node)"))"
  if_debug echo "npm: $(npm -v) (from $(ls -lha "$(which npm)"))"
  if_debug echo "npx: $(npx -v) (from $(ls -lha "$(which npx)"))"
  if_debug echo "corepack: $(corepack --version) (from $(ls -lha "$(which corepack)"))"
  if_debug echo "yarn: $(yarn -v) (from $(ls -lha "$(which yarn)"))"
elif [[ "$(nvm current)" != "${locally_resolved_nvm_version}" ]]; then
  if_debug echo "Switching to node version ${nvm_version}"
  use node "${nvm_version}"
fi
