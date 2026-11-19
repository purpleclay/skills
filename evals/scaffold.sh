#!/usr/bin/env bash
# Commits the project from fixture.sh to a fresh git repo, the starting point for each case.
set -euo pipefail

bash "$(dirname "$(realpath "$0")")/fixture.sh"

git init -q
git add .
git -c commit.gpgsign=false -c user.name=eval -c user.email=eval@example.invalid commit -qm "initial"
