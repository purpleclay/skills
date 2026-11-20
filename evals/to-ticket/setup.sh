#!/usr/bin/env bash
# Sourced by each case's scaffold.sh. Builds a git repo whose origin is acme/todo on GitHub,
# with the stand-in gh in .eval-bin/, and refuses to go on if that gh is not the one on PATH.
set -euo pipefail

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

git init -q
git remote add origin https://github.com/acme/todo.git
echo "# todo" >README.md
git add README.md
git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qm "initial"

mkdir .eval-bin
cp "$here/gh" .eval-bin/gh
chmod +x .eval-bin/gh
echo .eval-bin >>.git/info/exclude

if [ "$(command -v gh)" != .eval-bin/gh ]; then
  echo 'Run this suite with PATH=".eval-bin:$PATH" so that it never reaches GitHub.' >&2
  exit 1
fi

# spec <path> <title> [issue url]: saves a spec as /refine would, recording the issue it was
# refined from when given one.
spec() {
  mkdir -p "$(dirname "$1")"
  {
    [ -z "${3:-}" ] || printf -- '---\nissue: %s\n---\n\n' "$3"
    printf '# %s\n' "$2"
    body
  } >"$1"
}

# publishes <path> <title> <issue url or ""> <owner/repo#number, or owner/repo#new>: saves a spec
# like spec does, and tells the stand-in gh to expect it, published to that issue.
publishes() {
  spec "$@"
  printf '%s' "$2" >.eval-bin/want-title
  body >.eval-bin/want-body
  printf '%s' "$4" >.eval-bin/want-issue
}

body() {
  cat <<'MD'

## Goal

People can see when each todo is due, so they know what to do first.

## Current behaviour

`todo list` prints each todo's number, text and the date it was added. Todos have no due date.

## Acceptance criteria

- [ ] `todo add "pay rent" --due 2026-12-01` saves a todo due on that date.
- [ ] `todo list` shows "(due 2026-12-01)" after a todo's text, and nothing for a todo with no due date.
- [ ] A `--due` value that is not a date, such as `$HOME` or "next week", is rejected:

  ```sh
  # prints an error and exits 2
  todo add "pay rent" --due 'next week'
  ```

## Out of scope

- Reminders

## Constraints

- Public contract change: no
- Data migration: no
- Security boundary: no
MD
}
