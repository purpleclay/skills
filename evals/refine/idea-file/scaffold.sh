#!/usr/bin/env bash
# The repo from the shared scaffold.sh, plus the idea the case gives /refine as a file, which git
# does not track.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/../scaffold.sh"

mkdir -p ideas
cat >ideas/backlog-item.md <<'MD'
Let people archive a finished todo, so that `todo list` only shows what is left to do.
MD
