#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wrapper to run whatever backup program I need to to
# backup $HOME in say systemd/launchd
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

base="${base:-$HOME}"
ignorefile="${base}/.kopiaignore"

genignore() {
  printf "finding stuff not worth backing up\n" >&2
  start=$(date +%s)
  install -m644 "${_dir}/../backup/excludes" "${ignorefile}"

  {
    printf "\n"

    # symlinks pointing to /nix/store aren't worth wasting bytes on
    # backing up
    find "${base}" -lname '/nix/store/*' 2> /dev/null | sed -e "s|${base}/||g"

    # Nor are any non file/dir/symlinks in general
    find "${base}" \( -not -type f -and -not -type d -and -not -type l \) 2> /dev/null | sed -e "s|${base}/||g"
  } >> "${ignorefile}"

  # For macos use the same stuff backupd ignores
  if [ "$(uname -a)" = "Darwin" ]; then
    sysexclude=/System/Library/CoreServices/backupd.bundle/Contents/Resources/StdExclusions.plist

    {
      # The .exludes file might not have a trailing \n so add it just in case
      # blank lines is not a huge problem
      printf "\n"

      # Anything that apps specify as don't backup this key
      /usr/bin/mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'"
      printf "\n"

      if [ -f $sysexclude ]; then
        # Stuff from here that time machine ignores, so guessing we should too
        #
        # Note, if I were backing up more than $HOME I'd add a loop and include
        # ContentsExcluded and PathsExcluded in as well as UserPathsExcluded
        #
        # Though the entire thing seems missing in recent macos versions so whatever.
        /usr/bin/defaults read $sysexclude UserPathsExcluded | sed -e 's/["]$//' -e '/^[(]$/d' -e '/^[)]$/d' -e 's/["][,]//' | tr -d '    "'
      fi
    }
  fi
  end=$(date +%s)

  # Crappy optimizaton to only cache results of ^^^ for a day to save
  # on backup times. This adds up in that for macos a warm backup
  # takes around 3 minutes, with about 2 minutes comprising getting
  # all the find/mdfind/etc... work dominating the timing.
  #
  # If I ever want to force things I can just remove ~/.kopiaignore
  # and it'll regen so watever.
  printf "took %d seconds to calculate\n" $((end - start))
}

regen=false
if [ -e "${ignorefile}" ]; then
  # Only if the ignore file exists, see if its older than a day and
  # if so then regenerate it, otherwise use the last values as they
  # likely haven't changed a lot.

  fage=$(stat --format='%Y' "${ignorefile}")
  now=$(date +%s)
  age=$((now - fage))
  day=$((60 * 60 * 24))
  if [ "${age}" -ge "${day}" ]; then
    regen=true
  fi
else
  regen=true
fi

printf "start\n" >&2

if ${regen}; then
  printf "generating %s\n" "${ignorefile}"
  genignore
fi

# Always tag runs with script
#
# Additionally if we're in a tty tag that as well so I can filter out
# manual backups from non.
cmd="kopia snapshot create ${base} --tags script:true --parallel=4 --log-level=debug"

printf "cmd: %s\n" "${cmd}" >&2
${cmd}
printf "end\n" >&2
