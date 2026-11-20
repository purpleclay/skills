#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$(realpath "$0")")/../setup.sh"

large specs/sync.md
ticket specs/sync.tickets 1 $'published: https://github.com/acme/todo/issues/12\nblocked-by:\n' "Serve each account's todos over HTTP" 1 2 3 4 5
ticket specs/sync.tickets 2 $'blocked-by: 1\n' 'Log in and out of a todo server' 6 7
ticket specs/sync.tickets 3 $'blocked-by: 1 2\n' 'Sync todos with `todo sync`' 8 9 10 11
echo acme/todo#12 >.eval-bin/order
echo 13 >.eval-bin/next-number
printf '%s\n' 'Log in and out of a todo server' 'Sync todos with `todo sync`' >.eval-bin/want-titles
printf '%s\n' 'acme/todo#13 acme/todo#12' 'acme/todo#14 acme/todo#12' 'acme/todo#14 acme/todo#13' >.eval-bin/want-edges
