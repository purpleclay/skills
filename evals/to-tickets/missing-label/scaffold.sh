#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

spec_body=bug_body publishes specs/empty-file.md 'Stop `todo` crashing on an empty todo file' '' acme/todo#new
printf '%s\n' documentation enhancement >.eval-bin/repo-labels
