#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

large specs/sync.md
ticket specs/sync.tickets 1 $'published: https://github.com/acme/todo/issues/12\nblocked-by:\n' "Serve each account's todos over HTTP" 1 2 3 4 5
ticket specs/sync.tickets 2 $'blocked-by: 1\npublishing: yes\n' 'Log in and out of a todo server' 6 7
ticket specs/sync.tickets 3 $'blocked-by: 1 2\n' 'Sync todos with `todo sync`' 8 9 10 11
echo acme/todo#12 >.eval-bin/order
echo 13 >.eval-bin/next-number
