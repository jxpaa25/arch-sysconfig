#!/usr/bin/env bash
# The desktop, its tools and apps.
set -euo pipefail
# shellcheck source=install/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# One transaction, so that shared dependencies resolve the same way on every run.
install_pkgs desktop cli dev security apps
install_aur aur
