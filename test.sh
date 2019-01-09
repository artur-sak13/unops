#!/usr/bin/env bash
set -e
set -o pipefail

mapfile -t dirs < <(find "${PWD}/ansible/roles" -maxdepth 1 -type d  ! -name "*roles*")

for dir in "${dirs[@]}"; do
  base=$(basename "$dir")

  (
    set -x
    cd "$dir"
    molecule lint
  )

  echo
  echo "Sucessfully linted role ${base}!"
  echo
done
