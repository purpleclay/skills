#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

large specs/sync.md
echo 2 >.eval-bin/fail
