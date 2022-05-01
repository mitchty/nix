#!/usr/bin/env zsh
#-*-mode: Shell-script; coding: utf-8;-*-
# File: st-conflicts.zsh
# Copyright: 2020 Mitchell James Tishmack
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

# Allow different DIFF programs
DIFF=${DIFF:-git diff --no-index}

# Treat inputs as binary? Aka run the diff through xxd or not
BINMODE=

start="${1:-$_dir}"

for file in $(find "${start}" -type f -name "*sync-conflict*"); do
  # original file is left hand side, conflict is the right
  lhs=$(echo ${file} | sed -E -e 's/[.]sync-conflict-[[:digit:]]{8}-[[:digit:]]{6}-[A-Z0-9]{7}//g')
  rhs=${file}
  if [ -z "${BINMODE}" ]; then
    eval ${DIFF} =(xxd ${lhs}) =(xxd ${rhs})
  else
    eval ${DIFF} "${lhs}" "${rhs}"
  fi
  # iff stdin is a tty, we can prompt for changes, otherwise we act like a
  # glorified diff program
  if [ -t 0 ]; then
    ls -dal ${lhs} ${rhs}
    echo "# diff between ${lhs} ${rhs}"
    read "choice?Keep a or b? "
    if [[ "$choice" =~ ^[ab]$ ]]; then
      # Iff they choose a (conflict/rhs), move that to the original filename
      # otherwise remove the conflict file
      if [ "$choice" = 'a' ]; then
        echo rm "$rhs"
        rm "$rhs"
      else
        echo mv "$rhs" "$lhs"
        mv "$rhs" "$lhs"
      fi
    else
      printf "invalid choice %s" > /dev/stderr
      exit 1
    fi
  fi
done
