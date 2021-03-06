#!/usr/bin/env bash

fork_point=$(git merge-base --fork-point origin/master)
changed=$(git diff --name-only $fork_point apps/site/assets/css)

if [ -z "$changed" ]; then
  echo "No CSS files changed relative to origin/master fork point."
else
  rbenv local 2.4.1
  gem install scss_lint -v 0.59.0
  scss-lint $changed
fi
