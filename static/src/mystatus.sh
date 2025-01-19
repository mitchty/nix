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
  printf '{"name":"%s","full_text":"%s"' "${block:-unknown}" "${1}"
  if shift; then
    if [ -n "$1" ]; then
      printf ',"color": "%s"' "$1"
    fi
  fi
  printf '}'
}

ryg() {
  val=$1
  shift
  rlim="${1:-90}"
  shift > /dev/null 2>&1 || :
  ylim="${1:-60}"
  shift > /dev/null 2>&1 || :
  glim="${1:-40}"

  if [ ${val} -ge $rlim ]; then
    # red
    printf "#cc0000"
  elif [ ${val} -ge $ylim ]; then
    # yellow
    printf "#eeee00"
  elif [ ${val} -ge $glim ]; then
    # green
    printf "#00cc00"
  else
    # grey for "not worth caring"
    printf "#cccccc"
  fi
}

# ^ but in reverse, not bothering to generalize this junk for now
gyr() {
  val=$1
  shift
  rlim="${1:-20}"
  shift > /dev/null 2>&1 || :
  ylim="${1:-60}"
  shift > /dev/null 2>&1 || :
  glim="${1:-80}"

  if [ ${val} -ge $glim ]; then
    # grey for "not worth caring"
    printf "#cccccc"
  elif [ ${val} -ge $ylim ]; then
    # green
    printf "#00cc00"
  elif [ ${val} -ge $rlim ]; then
    # yellow
    printf "#eeee00"
  else
    # red
    printf "#cc0000"
  fi
}

while true; do
  printf ',['

  bat='/sys/class/power_supply/BAT0'

  if [ -e "${bat}" ]; then
    cap="$(cat ${bat}/capacity)"
    status="$(cat ${bat}/status)"
    ind=''
    indc=

    out=false
    block=battery

    if [ "${status}" = "Charging" ]; then
      ind="+"
      indc="#00cc00"

      # Don't dump out the battery status if we're charging and over 95%
      # charged, its close enough for government work.
      if [ "${cap}" -lt 95 ]; then
        out=true
      fi
    fi

    if [ "${status}" = "Discharging" ]; then
      ind="-"
      indc="#cc0000"

      # Same for discharging, only bother once under 95% battery
      if [ "${cap}" -lt 95 ]; then
        out=true
      fi
    fi

    if $out; then
      block "bat "

      if [ -n "${indc}" ] && $out; then
        block "${ind}" ${indc}
      fi

      if $out; then
        block "${cap}%" $(gyr $(printf "%0.0f" ${cap}))
      fi

      if command -v acpi > /dev/null 2>&1; then
        if $out; then
          tim=$(acpi -b | awk '{print $5}')
          h=$(echo ${tim} | awk -F: '{print $1}')
          m=$(echo ${tim} | awk -F: '{print $2}')
          if [ "${h}" -gt 0 ]; then
            block "${h}h${m}m"
          else
            block "${m}m"
          fi
        fi
      fi
    fi
  fi

  block=cpu
  block "cpu "

  cpu_idle=$(top -b -d 1 -n 1 | awk '/Cpu/ {print $8}')
  cpu_pct=$(echo "100 - ${cpu_idle}" | bc -l)

  block "$(printf '%3.0f%%' ${cpu_pct})" $(ryg $(printf "%0.0f" ${cpu_pct}))

  free_b=$(free -blw)
  rams_tot=$(echo "${free_b}" | awk '/Mem:/ {print $2}')
  rams_free=$(echo "${free_b}" | awk '/Mem:/ {print $4}')
  rams_shared=$(echo "${free_b}" | awk '/Mem:/ {print $5}')
  rams_buffers=$(echo "${free_b}" | awk '/Mem:/ {print $6}')
  rams_cache=$(echo "${free_b}" | awk '/Mem:/ {print $7}')

  rams_used=$(echo "${rams_free} + ${rams_shared} + ${rams_buffers} + ${rams_cache}" | bc -l)

  rams_pct=$(echo "((${rams_tot}.0 - ${rams_used}.0) / ${rams_tot}.0) * 100.0" | bc -l)

  rams_ok=$(echo "${rams_used}.0/1024/1024/1024" | bc -l)

  block=memory
  block "mem "

  block "$(printf '%3.0f%%' ${rams_pct})" $(ryg $(printf "%0.0f" ${rams_pct}))

  # TODO Output should probably scale better somehow... though not sure I'll
  # have a system with MiB or TiB anytime soon. Future mitch problem.
  t=$(printf " %0.0f GiB " ${rams_ok})

  block "${t}"

  if command -v nvidia-smi > /dev/null 2>&1; then
    vals=$(nvidia-smi --query-gpu=utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv,noheader,nounits)
    gpu_pct=$(echo $vals | awk -F', ' '{print $1}')
    vram_pct=$(echo $vals | awk -F', ' '{print $2}')
    vram_free=$(echo $vals | awk -F', ' '{print $4}')

    block=gpu
    block "gpu "

    block "$(printf '%3.0f%%' ${gpu_pct})" $(ryg $(printf "%0.0f" ${gpu_pct}))

    block " vram "

    block "$(printf '%3.0f%%' ${vram_pct})" $(ryg $(printf "%0.0f" ${vram_pct}))

    block "${vram_free} MiB "
  fi

  if command -v rocm-smi > /dev/null 2>&1; then
    vals=$(rocm-smi | awk '/^[0-9]+ / {print}' | tr -d '%')
    gpu_pct=$(echo $vals | awk '{print $15}')
    vram_pct=$(echo $vals | awk '{print $14}')
    # free makes no sense for shared gpu/cpu ram setups so skipping it as all
    # the amd gpus I have are those type.
    block "gpu "

    block "$(printf '%3.0f%%' ${gpu_pct})" $(ryg $(printf "%0.0f" ${gpu_pct}))

    block " vram "

    block "$(printf '%3.0f%%' ${vram_pct})" $(ryg $(printf "%0.0f" ${vram_pct}))
  fi

  time=$(date +%Y-%m-%d\ %H:%M:%S)

  block=time
  block "${time}"

  printf ']\n'

  rint=$(randint 1 7)
  sleep $rint

  prior=false
done
