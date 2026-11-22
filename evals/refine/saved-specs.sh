#!/usr/bin/env bash
# The repo from scaffold.sh, plus two saved specs: one /refine stopped refining after its second
# round, and one saved as ready before /refine recorded state, last worked on earlier.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/scaffold.sh"

mkdir -p .git/refine

cat >.git/refine/show-a-due-date-on-each-todo.md <<'MD'
# Show a `due` date on each todo

## Goal

People can see when each todo is due, so they know what to do first.

## Current behaviour

`todo list` prints each todo's number and text. Todos have no due date.

## Acceptance criteria

- [ ] `todo add "pay rent" --due 2026-12-01` saves a todo due on that date.
- [ ] `todo list` shows "(due 2026-12-01)" after a todo's text, and nothing for a todo with no due date.

## Out of scope

- Reminders

## Constraints

- Public contract change: no
- Data migration: no
- Security boundary: no
MD
touch -t 202611010900 .git/refine/show-a-due-date-on-each-todo.md

cat >.git/refine/mark-a-todo-as-done.md <<'MD'
---
state: in progress
---

# Mark a todo as done

## Goal

Anyone who uses todo can mark a todo as done, so they can see what is left to do.

## Current behaviour

## Acceptance criteria

- [ ] `todo done 2` marks the second todo in `todo list` as done and prints nothing.
- [ ] After `todo done 2`, `todo list` still lists the second todo.

## Out of scope

- Undoing a done todo: marking one done by mistake is fixed by adding it again.

## Constraints

## Open questions

- 5 · Done marker: How should `todo list` show a done todo, so it looks different from an open one?

## Interview

### Round 1

| Question                                                                         | What I took from your reply                                   |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| 1 · Goal check: Is the goal to let people mark a todo as done?                   | Yes, for anyone who uses todo, so they can see what is left.  |
| 2 · Done command: How should someone mark a todo as done?                        | `todo done 2` marks the second todo as done and prints nothing. |
| 3 · Undo: Should someone be able to mark a done todo as open again?              | Out of scope: they can add it again instead.                  |

### Round 2

| Question                                                                                        | What I took from your reply  |
| ----------------------------------------------------------------------------------------------- | ---------------------------- |
| 4 · Done todos listed: Once a todo is done, should it still appear in `todo list`?              | Yes, it stays in the list.   |
| 5 · Done marker: How should `todo list` show a done todo, so it looks different from an open one? | Not answered                 |
MD
