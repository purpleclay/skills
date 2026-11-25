#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

# publishes saves each spec as /refine would. Nothing should be published before the engineer picks.
publishes .git/refine/show-a-due-date-on-each-todo.md 'Show a `due` date on each todo'
publishes .git/refine/mark-a-todo-as-done.md 'Mark a todo as done'
in_progress .git/refine/sync-todos-between-devices.md 'Sync todos between devices'
