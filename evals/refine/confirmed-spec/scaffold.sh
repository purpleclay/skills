#!/usr/bin/env bash
# The project from fixture.sh, plus an in-progress spec whose every question is settled, as it stands
# when /refine shows it for the engineer to confirm. Runs can't write under .git/, so the git
# directory is .gitdir instead, which lets /refine save the confirmed spec and end as it would for
# real, rather than report a refused save.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/../fixture.sh"

git init -q --separate-git-dir=.gitdir
echo "gitdir: .gitdir" >.git
echo /.gitdir >>.gitdir/info/exclude
git add .
git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qm "initial"

mkdir -p .gitdir/refine

cat >.gitdir/refine/mark-a-todo-as-done.md <<'MD'
---
state: in progress
---

# Mark a todo as done

## Goal

Anyone who uses todo can mark a todo as done, so they can see what is left to do.

## Current behaviour

`todo list` prints each todo's number and text. There is no way to mark a todo as done.

## Acceptance criteria

- [ ] `todo done 2` marks the second todo in `todo list` as done and prints nothing.
- [ ] After `todo done 2`, `todo list` shows the second todo with "[x]" before its text, and every open todo with "[ ]".

## Out of scope

- Undoing a done todo: marking one done by mistake is fixed by adding it again.

## Constraints

- Public contract change: no
- Data migration: no
- Security boundary: no

## Interview

### Round 1

| Question                                                                         | What I took from your reply                                     |
| -------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| 1 · Goal check: Is the goal to let people mark a todo as done?                   | Yes, for anyone who uses todo, so they can see what is left.    |
| 2 · Done command: How should someone mark a todo as done?                        | `todo done 2` marks the second todo as done and prints nothing. |
| 3 · Undo: Should someone be able to mark a done todo as open again?              | Out of scope: they can add it again instead.                    |

### Round 2

| Question                                                                                          | What I took from your reply                    |
| ------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| 4 · Done marker: How should `todo list` show a done todo, so it looks different from an open one? | "[x]" before a done todo, "[ ]" before an open one. |
| 5 · Constraints: No public contract change, data migration or security boundary. Right?           | Confirmed: no to all three.                    |
MD
