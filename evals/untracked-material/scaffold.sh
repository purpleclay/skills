#!/usr/bin/env bash
# The repo from the shared scaffold.sh, plus notes that git does not track.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/../scaffold.sh"

mkdir -p drafts
cat > drafts/done-sketch.md <<'MD'
# Done flag sketch

- `todo done 3` marks item 3 as done.
- `todo list` shows done items with an `[x]` prefix and open items with `[ ]`.
- Done items keep their number.
- Leave `todo add` alone.
MD
