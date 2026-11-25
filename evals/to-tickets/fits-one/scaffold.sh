#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

spec_body=tidy_body publishes specs/tidy.md 'Tidy what `todo` prints' '' acme/todo#new
