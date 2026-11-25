#!/usr/bin/env bash
# Sourced by each case's scaffold.sh. Builds a git repo whose origin is acme/todo on GitHub,
# with the stand-in gh in .eval-bin/, and refuses to go on if that gh is not the one on PATH.
set -euo pipefail

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

git init -q
git remote add origin https://github.com/acme/todo.git
echo "# todo" >README.md
# The code the specs describe, for the surveyor to read.
cat >todo.py <<'PY'
"""todo: a command-line todo list, kept in a JSON file in the home directory."""
import argparse
import datetime
import json
import pathlib

PATH = pathlib.Path.home() / ".todo.json"


def load():
    if not PATH.exists():
        return []
    with PATH.open() as f:
        return json.load(f)


def save(todos):
    PATH.write_text(json.dumps(todos, indent=2))


def add(text):
    todos = load()
    todos.append({"text": text, "added": datetime.date.today().isoformat()})
    save(todos)


def show():
    for n, todo in enumerate(load(), 1):
        print(f"{n}. {todo['text']} [added {todo['added']}]")


def main():
    parser = argparse.ArgumentParser(prog="todo")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("add").add_argument("text")
    sub.add_parser("list")
    args = parser.parse_args()
    if args.command == "add":
        add(args.text)
    else:
        show()


if __name__ == "__main__":
    main()
PY
cat >test_todo.py <<'PY'
import todo


def test_add_then_list(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(todo, "PATH", tmp_path / "todo.json")
    todo.add("pay rent")
    todo.show()
    assert "1. pay rent [added " in capsys.readouterr().out
PY
git add README.md todo.py test_todo.py
git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qm "initial"

mkdir .eval-bin
cp "$here/gh" .eval-bin/gh
chmod +x .eval-bin/gh
echo .eval-bin >>.git/info/exclude

if [ "$(command -v gh)" != .eval-bin/gh ]; then
  echo 'Run this suite with PATH=".eval-bin:$PATH" so that it never reaches GitHub.' >&2
  exit 1
fi

# spec <path> <title> [issue url]: saves a spec as /refine would, or, given an issue url, as it did
# before it stopped recording the issue a spec was refined from.
spec() {
  mkdir -p "$(dirname "$1")"
  {
    [ -z "${3:-}" ] || printf -- '---\nissue: %s\n---\n\n' "$3"
    printf '# %s\n' "$2"
    "${spec_body:-body}"
  } >"$1"
}

# publishes <path> <title> <issue url or ""> <owner/repo#number, or owner/repo#new>: saves a spec
# like spec does, and tells the stand-in gh to expect it, published to that issue. Both save the
# due-date spec, or the body the function named by spec_body prints.
publishes() {
  spec "$@"
  printf '%s' "$2" >.eval-bin/want-title
  "${spec_body:-body}" >.eval-bin/want-body
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

# A spec that fixes behaviour that is wrong today: todo.py crashes on an empty file.
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

# A spec with many criteria, each a small change to todo.py, that fits in one ticket.
tidy_body() {
  cat <<'MD'

## Goal

What `todo` prints is easier to read, so people can scan their list at a glance.

## Current behaviour

`todo list` prints each todo as "1. pay rent [added 2026-11-01]". `todo add` prints nothing.

## Acceptance criteria

- [ ] `todo list` prints the number of each todo right-aligned to the width of the largest number.
- [ ] `todo list` prints the added date as "added 1 Nov" instead of "[added 2026-11-01]".
- [ ] `todo list` with no todos prints "Nothing to do".
- [ ] `todo add "pay rent"` prints "Added 3. pay rent", with the new todo's number.
- [ ] `todo add ""` prints "A todo needs some text" and exits 2.
- [ ] `todo add` trims spaces from the start and end of the text before saving it.
- [ ] `todo list` cuts text longer than 60 characters to 59 followed by "…".
- [ ] `todo list --plain` prints only each todo's text, one a line.
- [ ] `todo` with no command prints the same help as `todo --help` and exits 0.
- [ ] `todo --version` prints "todo 1.0".

## Out of scope

- Colour

## Constraints

- Public contract change: no
- Data migration: no
- Security boundary: no
MD
}

# drifted: changes todo.py so that todos already have a due date, as the due-date spec asks.
drifted() {
  cat >todo.py <<'PY'
"""todo: a command-line todo list, kept in a JSON file in the home directory."""
import argparse
import datetime
import json
import pathlib

PATH = pathlib.Path.home() / ".todo.json"


def load():
    if not PATH.exists():
        return []
    with PATH.open() as f:
        return json.load(f)


def save(todos):
    PATH.write_text(json.dumps(todos, indent=2))


def add(text, due=None):
    todos = load()
    todo = {"text": text, "added": datetime.date.today().isoformat()}
    if due:
        todo["due"] = due.isoformat()
    todos.append(todo)
    save(todos)


def show():
    for n, todo in enumerate(load(), 1):
        due = f" (due {todo['due']})" if todo.get("due") else ""
        print(f"{n}. {todo['text']}{due} [added {todo['added']}]")


def main():
    parser = argparse.ArgumentParser(prog="todo")
    sub = parser.add_subparsers(dest="command", required=True)
    add_cmd = sub.add_parser("add")
    add_cmd.add_argument("text")
    add_cmd.add_argument("--due", type=datetime.date.fromisoformat)
    sub.add_parser("list")
    args = parser.parse_args()
    if args.command == "add":
        add(args.text, args.due)
    else:
        show()


if __name__ == "__main__":
    main()
PY
  git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qam "add due dates"
}

# large <path> [issue url]: saves, as /refine would, a spec too large for one ticket, and tells the
# stand-in gh which acceptance criteria the published issues must hold between them.
large() {
  mkdir -p "$(dirname "$1")"
  {
    [ -z "${2:-}" ] || printf -- '---\nissue: %s\n---\n\n' "$2"
    printf '# Sync todos between devices\n'
    large_body
  } >"$1"
  large_body | grep '^- \[ \] ' >.eval-bin/want-criteria
}

# in_progress <path>: saves the large spec as /refine saves one it is still refining.
in_progress() {
  mkdir -p "$(dirname "$1")"
  {
    printf -- '---\nstate: in progress\n---\n\n# Sync todos between devices\n'
    large_body
  } >"$1"
}

large_body() {
  cat <<'MD'

## Goal

People who use todo on more than one computer see the same todos on each, without copying files by hand.

## Current behaviour

`todo` keeps todos in a JSON file in the user's home directory, and each command that changes a todo writes that file itself. `todo-server --port 8080` serves one shared list of todos over HTTP, with an endpoint for each command that changes a field of a todo and no accounts, so anyone who can reach it can read and change every todo.

## Acceptance criteria

- [ ] `todo-server` keeps each account's todos apart in a SQLite database, and a restart loses none of them.
- [ ] `POST /accounts` with an email and password creates an account and returns 201, and returns 409 when the email is taken.
- [ ] `POST /sessions` with a valid email and password returns a token, and returns 401 otherwise.
- [ ] Every `todo-server` endpoint other than `POST /accounts` and `POST /sessions` returns 401 without a valid token.
- [ ] Every `todo-server` endpoint reads and changes only the todos of the account whose token it was given.
- [ ] `todo login --server https://todo.example.com` asks for an email and password, and saves the token so later commands use it.
- [ ] `todo logout` deletes the saved token.
- [ ] Every `todo` command that changes a todo records the change, so that the next `todo sync` sends it.
- [ ] `todo sync` sends the changes recorded since the last sync to the server, and saves changes from the server locally.
- [ ] When a todo changed on two computers since the last sync, `todo sync` keeps the most recent change and prints which todo it overwrote.
- [ ] `todo sync` without a saved token prints "run todo login first" and exits 1.

## Out of scope

- Sharing todos between accounts
- A web interface

## Constraints

- Passwords are stored only as salted hashes.
- Public contract change: yes (new commands and accounts on every endpoint)
- Data migration: yes (the shared todos on the server move into accounts)
- Security boundary: yes (accounts and tokens)
MD
}

# big: grows todo.py and adds todo_server.py, as the large spec describes, to about 12,000 lines
# each. No command or endpoint shares code with another, so a change to all of them means reading
# all of them: together they are too much for one agent, and either alone is not.
big() {
  local verbs="set clear copy append prefix pin unpin lock unlock reset" v f
  local fields="priority colour project note owner place estimate effort area context energy mood tag link source reviewer phase sprint risk size budget client contact team stage channel region language platform version release milestone theme topic category audience goal outcome metric deadline location device account"
  {
    printf '"""todo: a command-line todo list, kept in a JSON file in the home directory."""\n'
    printf 'import argparse\nimport datetime\nimport json\nimport pathlib\nimport sys\n\n'
    printf 'PATH = pathlib.Path.home() / ".todo.json"\n\n\n'
    printf 'def load():\n    if not PATH.exists():\n        return []\n    with PATH.open() as f:\n        return json.load(f)\n\n\n'
    printf 'def save(todos):\n    PATH.write_text(json.dumps(todos, indent=2))\n\n\n'
    cat <<'PY'
def add(text):
    todos = load()
    todos.append({"text": text, "added": datetime.date.today().isoformat()})
    save(todos)


def show():
    for n, todo in enumerate(load(), 1):
        print(f"{n}. {todo['text']} [added {todo['added']}]")


def cmd_add(args):
    add(args.text)
    return 0


def cmd_list(args):
    show()
    return 0


PY
    for v in $verbs; do for f in $fields; do
      cat <<PY
def cmd_${v}_${f}(args):
    """todo ${v}-${f} <n> [value]: ${v}s the ${f} of todo n."""
    todos = load()
    n = int(args.n) - 1
    if n < 0 or n >= len(todos):
        print(f"no todo {args.n}", file=sys.stderr)
        return 1
    todo = todos[n]
    old = todo.get("${f}")
    if "${v}" in ("lock", "pin") and todo.get("${f}_held"):
        print(f"todo {args.n}: ${f} is held", file=sys.stderr)
        return 1
    if "${v}" in ("clear", "reset", "unpin", "unlock"):
        todo.pop("${f}", None)
    elif "${v}" in ("append", "prefix") and old:
        todo["${f}"] = old + " " + args.value if "${v}" == "append" else args.value + " " + old
    else:
        todo["${f}"] = args.value
    todo["${f}_changed"] = datetime.date.today().isoformat()
    save(todos)
    print(f"todo {args.n}: ${f} {old!r} -> {todo.get('${f}')!r}")
    return 0


PY
    done; done
    printf 'def main():\n    parser = argparse.ArgumentParser(prog="todo")\n    sub = parser.add_subparsers(dest="command", required=True)\n'
    printf '    p = sub.add_parser("add")\n    p.add_argument("text")\n    p.set_defaults(run=cmd_add)\n    sub.add_parser("list").set_defaults(run=cmd_list)\n'
    for v in $verbs; do for f in $fields; do
      printf '    p = sub.add_parser("%s-%s")\n    p.add_argument("n")\n    p.add_argument("value", nargs="?")\n    p.set_defaults(run=cmd_%s_%s)\n' "$v" "$f" "$v" "$f"
    done; done
    printf '    args = parser.parse_args()\n    sys.exit(args.run(args))\n\n\nif __name__ == "__main__":\n    main()\n'
  } >todo.py
  {
    printf '"""todo-server: serves one shared list of todos over HTTP, with no accounts."""\n'
    printf 'import argparse\nimport datetime\nimport http.server\nimport json\nimport pathlib\n\n'
    printf 'PATH = pathlib.Path("todos.json")\n\n\n'
    for v in $verbs; do for f in $fields; do
      cat <<PY
def handle_${v}_${f}(request, n):
    """POST /todos/<n>/${v}-${f}: ${v}s the ${f} of todo n."""
    length = int(request.headers.get("Content-Length", 0))
    body = json.loads(request.rfile.read(length) or b"{}")
    todos = json.loads(PATH.read_text()) if PATH.exists() else []
    if n < 1 or n > len(todos):
        request.send_response(404)
        request.end_headers()
        return
    todo = todos[n - 1]
    old = todo.get("${f}")
    if "${v}" in ("clear", "reset", "unpin", "unlock"):
        todo.pop("${f}", None)
    elif "${v}" in ("append", "prefix") and old:
        todo["${f}"] = old + " " + body.get("value", "")
    else:
        todo["${f}"] = body.get("value")
    todo["${f}_changed"] = datetime.date.today().isoformat()
    PATH.write_text(json.dumps(todos, indent=2))
    request.send_response(200)
    request.send_header("Content-Type", "application/json")
    request.end_headers()
    request.wfile.write(json.dumps(todo).encode())


PY
    done; done
    printf 'ROUTES = {\n'
    for v in $verbs; do for f in $fields; do printf '    "%s-%s": handle_%s_%s,\n' "$v" "$f" "$v" "$f"; done; done
    printf '}\n\n\nclass Handler(http.server.BaseHTTPRequestHandler):\n    def do_POST(self):\n        _, _, n, action = self.path.split("/")\n        ROUTES[action](self, int(n))\n\n\n'
    printf 'def main():\n    parser = argparse.ArgumentParser(prog="todo-server")\n    parser.add_argument("--port", type=int, default=8080)\n    args = parser.parse_args()\n    http.server.HTTPServer(("", args.port), Handler).serve_forever()\n\n\nif __name__ == "__main__":\n    main()\n'
  } >todo_server.py
  git add todo.py todo_server.py
  git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qm "add a command and an endpoint for each field"
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
