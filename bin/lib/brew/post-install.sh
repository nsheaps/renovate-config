#!/usr/bin/env bash

# WARNING: Brew will clean up environment variables, so some that
# may be set in the shell will not be available here.
# See: https://github.com/Homebrew/brew/blob/master/bin/brew#L273
# Since we don't intercept the brew command before running anything,
# we can't set environment variables here (even if we wanted to dump
# them to file and then re-source the values).
# The following won't work:
#   - if_debug

set -euo pipefail

# PATH passed by brew doesn't contain everything, so we need to manually
# construct it and add it again.
#
# Details in https://github.com/gathertown/gather-town-v2/pull/7054 and
# [EP-747].
if ! command -v brew &>/dev/null; then
  PATH="$HOMEBREW_PREFIX/bin:$PATH"
fi

# Re-run ourself with bash explictly to ensure we're using the latest
# version of bash. At the time of this script being called, bash does
# not always point to the homebrew managed bash. However, our prefix
# logic at the top resolves this.
if [[ -z "${HOMEBREW_BUNDLE_BASH_WRAPPED:-}" ]]; then
  export HOMEBREW_BUNDLE_BASH_WRAPPED=true
  exec bash "$0"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# IS_CI is set if we're running in CI.
IS_CI="${1:-false}"

# shellcheck source=../stdlib.sh
source "$SCRIPT_DIR/../stdlib.sh"

debug 'Running post-install tasks for brew bundle...'

if_debug debug "Brew version: $(brew --version)"
if_debug debug "Brew prefix: $(brew --prefix)"

function line-exists-in-file() {
  FILE="$1"
  LINE="$2"
  # todo: make this platform independent, macos and linux have different grep
  if [ ! -f "$FILE" ]; then
    # file doesn't exist, so line can't exist
    return 1
  fi
  if grep -qxF "$LINE" "$FILE"; then
    # line exists
    return 0
  else
    # line doesn't exist
    return 1
  fi
}

function enforce-line-in-file() {
  FILE="$1"
  LINE="$2"
  # $3 is optional, default "line"
  WHAT="${3:-line}"
  if [ -f "$FILE" ]; then
    if line-exists-in-file "$FILE" "$LINE"; then
      if_debug debug "✅ already in $FILE"
    else
      # if the file is write protected, use sudo
      if [ ! -w "$FILE" ]; then
        # ensure sudo access
        sudo -v -p "🔒 requesting sudo access for protected file $1, please enter password: "
        echo "🔒 adding to $FILE with sudo"
        echo "$2" | sudo tee -a "$FILE" >/dev/null
      else
        # echo "adding to $1"
        printf "\n%s" "$LINE" >>"$FILE"
      fi
      success "✅ added $WHAT to $FILE"
    fi
  else
    if_debug warn "❓ $FILE does not exist"
  fi
}

function enforce-rc-file-exists-if-active-shell() {
  if [[ "$SHELL" == *bash ]]; then
    if_debug debug "🔍 Found bash shell"
    if [[ ! -f "$HOME/.bashrc" ]]; then
      if_debug debug "🔍 No ~/.bashrc found, creating one..."
      touch "$HOME/.bashrc"
    fi
  elif [[ "$SHELL" == *zsh ]]; then
    if_debug debug "🔍 Found zsh shell"
    if [[ ! -f "$HOME/.zshrc" ]]; then
      if_debug debug "🔍 No ~/.zshrc found, creating one..."
      touch "$HOME/.zshrc"
    fi
  else
    warn "Using unsupported shell: $SHELL"
    warn "Please make sure bin/lib/brew/post-install.sh's tasks are accomplished for your shell"
    warn "If possible, please contribute to the post-install.sh script to account for your shell choice"
  fi
}

setup_shells() {
  if_debug echo "🍺 Adding nvm and direnv shell hooks..."
  # use rc file instead of profile because RC files are sourced by both
  # login and non-login shells (meaning they're always sourced, whereas
  # profile won't be sourced if running the shell directly (eg bash -c
  # "command"))
  enforce-rc-file-exists-if-active-shell

  # shellcheck disable=SC2016 # We want this to not expand.
  for shell in "zsh" "bash"; do
    shellrc="$HOME/.${shell}rc"

    # direnv
    enforce-line-in-file "$shellrc" 'eval "$(direnv hook '"$shell"')"' "direnv hook"

    # nvm
    enforce-line-in-file "$shellrc" 'export NVM_DIR="$HOME/.nvm"' "nvm dir"
    enforce-line-in-file "$shellrc" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' "nvm hook"
    enforce-line-in-file "$shellrc" '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' "nvm completion hook"
  done
  if_debug echo "done"

  # If nvm.sh is not a link, then it's not being managed by homebrew, so
  # we should migrate it. Notable exception is we don't care about CI
  # systems.
  if [[ -z "$IS_CI" ]]; then
    if ! readlink "$HOME/.nvm/nvm.sh" &>/dev/null; then
      echo "➡️ Migrating to homebrew managed nvm ..."
      export NVM_DIR="$HOME/.nvm"
      rm -rf "$NVM_DIR"

      # This forces the creation of the symlinks.
      "$SHELL" "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" &>/dev/null || true

      # Currently, homebrew does not link `bash_completion`. Instead of
      # requiring shellrc instances to be pointing to that path, we create
      # the link ourselves.
      bashCompDst="$NVM_DIR/bash_completion"
      if ! readlink "$bashCompDst" &>/dev/null; then
        rm -f "$bashCompDst"
        ln -s "$HOMEBREW_PREFIX/etc/bash_completion.d/nvm" "$bashCompDst"
      fi
      echo "done"

      # If we have direnv, we should reload it to trigger node installation.
      if command -v direnv &>/dev/null; then
        echo "ℹ️ Reloading direnv to ensure correct node version ..."
        direnv reload
        echo "done"
      fi
    fi
  fi
}

if [[ "$IS_CI" == "false" ]]; then
  setup_shells
else
  debug "Skipping shell setup, running in CI"
fi

# Track that `brew bundle install` was ran.
"$SCRIPT_DIR/../../helpers/update-actionable.sh" "Brewfile"
