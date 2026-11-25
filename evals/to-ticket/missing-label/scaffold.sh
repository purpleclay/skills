#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

publishes specs/empty-file.md 'Stop `todo` crashing on an empty todo file' bug_body
printf '%s\n' documentation enhancement >.eval-bin/repo-labels
