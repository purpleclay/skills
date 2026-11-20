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

# large <path> [issue url]: saves, as /refine would, a spec too large for one ticket, and tells the
# stand-in gh which acceptance criteria the published issues must hold between them, and which
# open questions they must keep.
large() {
  mkdir -p "$(dirname "$1")"
  {
    [ -z "${2:-}" ] || printf -- '---\nissue: %s\n---\n\n' "$2"
    printf '# Sync todos between devices\n'
    large_body
  } >"$1"
  large_body | grep '^- \[ \] ' >.eval-bin/want-criteria
  large_body | sed -n '/^## Open questions$/,$p' | grep '^- ' >.eval-bin/want-questions
}

large_body() {
  cat <<'MD'

## Goal

People who use todo on more than one computer see the same todos on each, without copying files by hand.

## Current behaviour

`todo` keeps todos in a JSON file in the user's home directory. Nothing talks to a network, and there are no accounts.

## Acceptance criteria

- [ ] `todo-server --port 8080` starts a server that keeps each account's todos in a SQLite database, and a restart loses none of them.
- [ ] `POST /accounts` with an email and password creates an account and returns 201, and returns 409 when the email is taken.
- [ ] `POST /sessions` with a valid email and password returns a token, and returns 401 otherwise.
- [ ] `GET /todos` with a valid token returns that account's todos as JSON, and returns 401 without one.
- [ ] `PUT /todos/{id}` with a valid token creates or replaces that todo, and never changes another account's todos.
- [ ] `todo login --server https://todo.example.com` asks for an email and password, and saves the token so later commands use it.
- [ ] `todo logout` deletes the saved token.
- [ ] `todo sync` sends local changes made since the last sync to the server, and saves changes from the server locally.
- [ ] When a todo changed on two computers since the last sync, `todo sync` keeps the most recent change and prints which todo it overwrote.
- [ ] `todo sync` without a saved token prints "run todo login first" and exits 1.
- [ ] The first `todo sync` after login uploads every existing local todo, and none is lost or duplicated.

## Out of scope

- Sharing todos between accounts
- A web interface

## Constraints

- Passwords are stored only as salted hashes.
- Public contract change: yes (new commands and an HTTP API)
- Data migration: yes (existing local todos are uploaded on the first sync)
- Security boundary: yes (accounts and tokens)

## Open questions

- Should `todo sync` also run after every `todo add`?
- How long does a token last before `todo login` is needed again?
MD
}

# ticket <dir> <n> <front matter> <title> <criteria...>: saves one ticket of an approved breakdown
# as /to-tickets would, holding the large spec's criteria at the positions given.
ticket() {
  local dir=$1 n=$2 front=$3 title=$4 i
  shift 4
  mkdir -p "$dir"
  {
    printf -- '---\n%s---\n\n# %s\n\n## Goal\n\nPeople who use todo on more than one computer get closer to seeing the same todos on each.\n\n' "$front" "$title"
    printf '## Current behaviour\n\n`todo` keeps todos in a JSON file in the home directory.\n\n## Acceptance criteria\n\n'
    for i in "$@"; do large_body | grep '^- \[ \] ' | sed -n "${i}p"; done
    printf '\n## Out of scope\n\n- Sharing todos between accounts\n\n## Constraints\n\n- Public contract change: yes\n- Data migration: no\n- Security boundary: yes\n'
  } >"$dir/$n.md"
}
