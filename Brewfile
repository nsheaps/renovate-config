return system "printenv" if ARGV[0] == "env"

# isCI is used to determine if we're running in CI or not.
isCI = ENV["CI"] == "true"
# Unfortunately, the Brewfile runs in a restricted environment, so doesn't
# have access to the full shell `PATH` to find the brew executable.
# Homebrew exposes some environment variables that we can use to find the
# brew configuration. In this case, we can use the env var, HOMEBREW_BREW_FILE.
# To see other env vars run `shell "printenv"` at the top of this file and run
# `brew bundle env`.
brew_path = ENV["HOMEBREW_BREW_FILE"]

# This file is ruby at it's heart and can run ruby code. It's executed
# in order, and so for "pre-install" we'll list dependencies that _used_
# to be installed by this that are now no longer needed.
def remove_formulae(formulae, all_formulae, brew_path)
  # intersection between formulae and all_formulae
  formulae_to_remove = formulae & all_formulae
  # if formulae_to_remove is empty, return
  return if formulae_to_remove.empty?
  formulae_joined_as_string = formulae_to_remove.join(" ")
  system "echo \"Uninstalling #{formulae_joined_as_string}...\""
  system "#{brew_path} uninstall #{formulae_joined_as_string}"
end

def pre_install(brew_path)
  # if we're running brew bundle check, skip the pre install
  return if ARGV[0] == "check"
  system "echo \"Running pre-install for brew bundle...\""

  if brew_path
    all_formulae = `#{brew_path} list --formulae --full-name -1`.split("\n")
    # Remove old formulae that are no longer needed
    remove_formulae([
      # keep this list small, packages may be depended on by others, so
      # only uninstall if necessary
    ], all_formulae, brew_path)
  else
    system "echo \"Error: Could not find env var HOMEBREW_BREW_FILE (used to find brew executable).\""
  end
end

def post_install(isCI)
  # if we're running brew bundle check, skip the post install
  return if ARGV[0] == "check"
  system "bin/lib/brew/post-install.sh #{isCI}"
end

pre_install(brew_path)

### Taps

### Formulae
brew "bash" # We use a newer version of Bash (>2007) for our scripts.
brew "coreutils"
brew "gh"
brew "git-lfs"
brew "gnu-sed"
brew "gnutls"
brew "htop"
brew "jq"
brew "pstree"
brew "watch"
brew "wget"
brew "yq"
brew "direnv"
brew "shellcheck" # Bash linting
brew "shfmt" # Bash formatting

at_exit do
  post_install(isCI)
end
