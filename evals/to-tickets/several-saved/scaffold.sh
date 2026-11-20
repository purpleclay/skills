#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

spec .git/refine/show-a-due-date-on-each-todo.md 'Show a `due` date on each todo'
spec .git/refine/mark-a-todo-as-done.md 'Mark a todo as done'
