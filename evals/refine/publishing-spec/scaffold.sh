#!/usr/bin/env bash
# The specs from saved-specs.sh, with a breakdown of the ready one that /to-tickets has started
# publishing: its first ticket is published and the second is not.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/../saved-specs.sh"

dir=.git/refine/show-a-due-date-on-each-todo.tickets
mkdir -p "$dir"
printf -- '---\nblocked-by:\npublished: https://github.com/acme/todo/issues/7\n---\n\n# Save a due date on each todo\n' >"$dir/1.md"
printf -- '---\nblocked-by: 1\n---\n\n# Show the due date in todo list\n' >"$dir/2.md"
