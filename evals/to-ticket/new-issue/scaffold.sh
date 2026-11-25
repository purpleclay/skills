#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

publishes specs/due-dates.md 'Show a `due` date on each todo'
