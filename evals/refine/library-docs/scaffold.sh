#!/usr/bin/env bash
# The repo from the shared scaffold.sh, with the store loading and saving through io/ioutil, which
# Go's documentation marks as deprecated.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/../scaffold.sh"

sed -i.bak -e 's/os\.ReadFile/ioutil.ReadFile/' -e 's/os\.WriteFile/ioutil.WriteFile/' \
	-e 's/^\t"errors"$/\t"errors"\n\t"io\/ioutil"/' internal/store/store.go
rm internal/store/store.go.bak

git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qam "load and save through ioutil"
