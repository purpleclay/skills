#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

large specs/sync.md https://github.com/other-org/other-repo/issues/7
echo other-org/other-repo#7 >.eval-bin/want-first
echo other-org/other-repo >.eval-bin/want-repo
