#!/usr/bin/env bash

# From https://github.com/divnix/digga/blob/main/examples/devos/shell/hooks/pre-commit.sh
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    against=HEAD
else
    # Initial commit: diff against an empty tree object
    against=$(${git}/bin/git hash-object -t tree /dev/null)
fi

changed_files=($(git diff-index --name-only --cached $against --diff-filter d))

# Format staged files
if ((${#changed_files[@]} != 0)); then
    treefmt "${changed_files[@]}" && git add "${changed_files[@]}"
fi
