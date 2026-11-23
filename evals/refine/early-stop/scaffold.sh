#!/usr/bin/env bash
# The specs from saved-specs.sh, with the in-progress one as /refine saves it once it has resumed and
# asked round 3, as the history shows: question 5 asked again and question 6 asked for the first time.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/../saved-specs.sh"

spec=.git/refine/mark-a-todo-as-done.md

sed -i.bak '/^- 5 · Done marker:/a\
- 6 · Done twice: What should happen when someone runs `todo done` on a todo that is already done?
' "$spec"
rm "$spec.bak"

cat >>"$spec" <<'MD'

### Round 3

| Question                                                                                          | What I took from your reply |
| ------------------------------------------------------------------------------------------------- | --------------------------- |
| 5 · Done marker: How should `todo list` show a done todo, so it looks different from an open one? | Not answered                |
| 6 · Done twice: What should happen when someone runs `todo done` on a todo that is already done?  | Not answered                |
MD
