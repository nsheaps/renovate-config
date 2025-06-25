#!/usr/bin/env bash

# shellcheck source=../bin/lib/stdlib.sh
source "${DIRENV_ROOT}/bin/lib/stdlib.sh"

# if ${DIRENV_ROOT}/.envrc.local.template exists
if [ ! -f "${DIRENV_ROOT}/.envrc.local" ]; then
  if_debug echo "Copying .envrc.local.template to .envrc.local"
  cp "${DIRENV_ROOT}/.envrc.local.template" "${DIRENV_ROOT}/.envrc.local"
fi

# if ${DIRENV_ROOT}/.envrc.local exists, source it
if [ -f "${DIRENV_ROOT}/.envrc.local" ]; then
  if_debug echo "Loading .envrc.local"

  # Why: We disable SC1091 because it's not always present, but if it is
  # we could benefit from loading it, potentially.
  #
  # shellcheck disable=SC1091 source=../.envrc.local
  source "${DIRENV_ROOT}/.envrc.local"
fi
