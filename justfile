# Renovate Config - Local Development Commands
#
# Prerequisites:
#   - just: https://github.com/caesar/just
#   - mise: https://mise.run
#
# Usage:
#   just          # Show available commands
#   just lint     # Run linters (fix if issues found)
#   just check    # Run all checks (alias for lint)

set unstable

# Default recipe: show help
default:
    @just --list

# Check for lint/format issues without fixing
lint-check:
    #!/usr/bin/env bash
    FAILED=false
    yarn biome check . || FAILED=true
    bin/lint-shell || FAILED=true
    [[ "$FAILED" == "false" ]]

# Fix lint/format issues
lint-fix:
    #!/usr/bin/env bash
    yarn biome check --write .
    bin/lint-shell --fix

# Run linters - auto-fix if issues found, CI handles detecting/committing changes
lint:
    #!/usr/bin/env bash
    if just lint-check; then
        exit 0
    fi
    echo "Lint errors found. Attempting to fix..."
    just lint-fix
    # Exit based on whether issues remain
    just lint-check

# Run all checks (lint)
check:
    just lint
