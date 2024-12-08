#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--e}"

printf '{"version": 1}\n[\n[]\n'

. $HOME/src/pub/github.com/mitchty/nix/static/src/lib.sh

prior=false

block() {
  if $prior; then
    printf ","
  else
    prior=true
  fi
  printf '{"name":"time","full_text":"%s"' "${1}"
  if shift; then
    if [ -n "$1" ]; then
      printf ',"color": "%s"' "$1"
    fi
  fi
  printf '}'
}

ryg() {
  val=$1
  rlim=90
  ylim=60

  if [ ${val} -ge $rlim ]; then
    # red
    printf "#cc0000"
  elif [ ${val} -ge $ylim ]; then
    # yellow
    printf "#cccccc"
  else
    # green
    printf "#00cc00"
  fi
}

while true; do
  if command -v nvidia-smi > /dev/null 2>&1; then
    vals=$(nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv,noheader,nounits)
    gpu_pct=$(echo $vals | awk -F', ' '{print $1}')
    vram_pct=$(echo $vals | awk -F', ' '{print $2}')
    vram_free=$(echo $vals | awk -F', ' '{print $4}')
  fi
  time=$(date +%Y-%m-%d\ %H:%M:%S)

  free_b=$(free -blw)
  rams_tot=$(echo "${free_b}" | awk '/Mem:/ {print $2}')
  rams_used=$(echo "${free_b}" | awk '/Mem:/ {print $3}')
  rams_free=$(echo "${free_b}" | awk '/Mem:/ {print $4}')

  hack=0.0

  rams_pct=$(echo "((${hack} + ${rams_used}) / (${hack} + ${rams_tot})) * 100.0" | nix run nixpkgs#bc -- -l)

  rams_free=$(echo "${rams_free} /1024/1024/1024" | nix run nixpkgs#bc -- -l)

  printf ',['

  block "mem "

  block "$(printf '%0.0f%%' ${rams_pct})" $(ryg $(printf "%0.0f" ${rams_pct}))

  t=$(printf " %0.0f GiB free " ${rams_free})

  block "${t}"

  if command -v nvidia-smi > /dev/null 2>&1; then
    block "gpu "

    block "$(printf '%0.0f%%' ${gpu_pct})" $(ryg $(printf "%0.0f" ${gpu_pct}))

    block " vram "

    block "$(printf '%0.0f%%' ${vram_pct})" $(ryg $(printf "%0.0f" ${vram_pct}))

    block "${vram_free} MiB free "
  fi

  block "${time}"

  printf ']\n'

  rint=$(randint 1 11)
  sleep $rint

  prior=false
done
