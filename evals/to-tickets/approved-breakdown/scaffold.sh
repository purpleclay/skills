#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

large specs/sync.md https://github.com/other-org/other-repo/issues/7
echo acme/todo >.eval-bin/want-repo
