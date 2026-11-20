#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

large specs/sync.md
large_body | grep '^- \[ \] ' | grep 'todo logout' >.eval-bin/want-alone
