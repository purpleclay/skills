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

# publishes <path> <title> [body function]: saves a spec as /refine would, with the body the
# function prints, the due-date spec's by default, and tells the stand-in gh to expect it.
publishes() {
  mkdir -p "$(dirname "$1")"
  {
    printf '# %s\n' "$2"
    "${3:-body}"
  } >"$1"
  printf '%s' "$2" >.eval-bin/want-title
  "${3:-body}" >.eval-bin/want-body
}

# in_progress <path> [title]: saves the due-date spec as /refine saves one it is still refining,
# under its own title by default.
in_progress() {
  mkdir -p "$(dirname "$1")"
  {
    printf -- '---\nstate: in progress\n---\n\n# %s\n' "${2:-Show a \`due\` date on each todo}"
    body
  } >"$1"
}

# A spec that adds behaviour.
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

# A spec that fixes behaviour that is wrong today.
bug_body() {
  cat <<'MD'

## Goal

People whose todo file is empty can still use todo, instead of seeing it crash.

## Current behaviour

When `~/.todo.json` exists but is empty, `todo list` and `todo add` crash with a JSON decoding traceback.

## Acceptance criteria

- [ ] When `~/.todo.json` is empty, `todo list` prints nothing and exits 0.
- [ ] When `~/.todo.json` is empty, `todo add "pay rent"` saves that todo as the only one.

## Out of scope

- Repairing a todo file that holds invalid JSON

## Constraints

- Public contract change: no
- Data migration: no
- Security boundary: no
MD
}
