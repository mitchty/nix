#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
#
# Allow using local (SC3043) even though its not "posix" can't find a relevant
# shell that doesn't support it. Even busybox sh does so eh.
#
# Same for SC2016, shellcheck seems to not like ${AWK:-awk} '/some/thing/' vs
# awk '/some/thing/' Its totally valid given I assign "something" to the top
# level by default so just globally ignore those "errors" as it lets me adjust
# commands at runtime.
#
#shellcheck disable=SC3043,SC2016
#
# General library utility functions I end up re-writing all over the damn place
# in random scripts I create. No more! Shared library it is for once.

# TODO: add tests for this in shellspec, for now just yeeted this from random
# disparate shell I have lying around. Future winter mitch problem. Suck it
# future mitch past mitch knows he's a jerk.

AWK="${AWK:-awk}"
GREP="${GREP:-grep}"
OD="${OD:-od}"
UNAME="${UNAME:-uname}"

# Silly functions to make certain filtering easier/be lazy.
nocomments() {
  ${GREP} -Ev '^[#].*'
}

squishws() {
  ${GREP} -Ev '^[[:space:]]*$'
}

hidepass() {
  ${GREP} -Evi 'password'
}

# Silly helper functions to run stuff on specific platforms only
onlinux() {
  if [ "Linux" = "$(${UNAME} -s)" ]; then
    "$@"
  fi
}

# These aren't args really just a way to chain commands.
#shellcheck disable=SC2120
onmac() {
  if [ "Darwin" = "$(${UNAME} -s)" ]; then
    "$@"
  fi
}

# Old env related stuff, not sure if useful anymore but good examples of....
# things written in anger I guess.

# cat out a : separated env variable
# variable is the parameter
cat_env() {
  set | ${GREP} '^'"$1"'=' > /dev/null 2>&1 && eval "echo \$$1" | tr ':' '
' | ${AWK} '!/^\s+$/' | ${AWK} '!/^$/'
}

# Convert a line delimited input to : delimited
to_env() {
  ${AWK} '!a[$0]++' < /dev/stdin | tr -s '
' ':' | sed -e 's/\:$//' | ${AWK} 'NF > 0'
}

# Unshift a new value onto the env var
# first arg is ENV second is value to unshift
# basically prepend value to the ENV variable
unshift_env() {
  new=$(eval "echo $2; echo \$$1" | to_env)
  eval "$1=${new}; export $1"
}

# Opposite of above, but echos what was shifted off
shift_env() {
  first=$(cat_env "$1" | head -n 1)
  rest=$(cat_env "$1" | ${AWK} '{if (NR!=1) {print}}' | to_env)
  eval "$1=$rest; export $1"
  echo "${first}"
}

# push $2 to $1 on the variable
push_env() {
  have=$(cat_env "$1")
  new=$(printf "%s
%s" "$have" "$2" | to_env)
  eval "$1=$new; export $1"
}

# Remove a line matched in $HOME/.ssh/known_hosts for when there are legit
# host key changes.
nukehost() {
  for x in "$@"; do
    sed -i -e "/$x/d" ~/.ssh/known_hosts
  done
}

# Git wrapper fn used like pushd/popd in that on success, you're in a dir/checkout
try_git() {
  # assume https if input doesn't contain a protocol string :// otherwise treat
  # it as golden and let git complain or not
  uri="${1}"
  shift
  uproto=$(printf "%s" "${uri}" | ${GREP} '://' > /dev/null 2>&1 && printf "%s" "${uri}" | sed -e 's|[:]\/\/.*||g')
  proto=${uproto:-https}
  wtbranch=${1:-}
  shift > /dev/null 2>&1
  # For wrapper functions, allow destination to be an env var iff unset and
  # nonnull and $3 is present use $3 or as a fallback use $HOME/src
  destination=${DEST:-${1:-$HOME/src/pub}}

  git_dir=$(printf "%s" "${uri}" | sed -e 's|.*[:]\/\/||g')
  rrepo="${proto}://${git_dir}"

  # strip user@, :NNN, and .git from input uri's
  repo="${destination}/"$(printf "%s" "${git_dir}" \
    | sed -e 's/\.git$//g' \
    | sed -e 's|.*\@||g' \
    | sed -e 's|\:[[:digit:]]\{1,\}\/|/|g' \
    | tr -d '~')

  # Abuse this to know if we cloned or created a worktree and cd'd into it or
  # not.
  ocwd=$(pwd)

  # What dir should it end up in?
  cdrepo="${repo}"

  # The clone step.
  if [ ! -d "${repo}" ]; then
    if git ls-remote "${rrepo}" > /dev/null 2>&1; then
      install -dm755 "${repo}"
      printf "git clone %s %s\n" "${rrepo}" "${repo}" >&2
      git clone --recursive "${rrepo}" "${repo}" || rmdir "${repo}"
      cdrepo="${repo}"
    else
      printf "%s doesn't look to be a git repository\n" "${rrepo}" >&2
      return 1
    fi
  fi

  # Handle if the last arg is a worktree dir or not
  if [ -n "${wtbranch}" ]; then
    # Find the default branch to not treat as a workspace
    rhead=$(git ls-remote "${repo}" HEAD | ${AWK} '!/remotes/ {print $1}')
    defbranch=$(git ls-remote "${repo}" 'refs/heads/*' | ${AWK} "/${rhead}/ {sub(/refs\/heads\//,X,\$0);print \$2}")

    # Treat the defaultbranch only as not a worktree branch
    if [ "${defbranch}" = "${wtbranch}" ]; then
      printf "error: worktree branch %s is the default branch not creating a worktree dir\n" "${wtbranch}" >&2
      return 1
    else
      # as workdir clone directories.
      wtdir="${repo}@${wtbranch}"
      cdrepo="${wtdir}"

      if [ ! -d "${wtdir}" ]; then
        if git branch -r --list 'origin/*' | ${GREP} -E "^\s+origin/${wtbranch}$" > /dev/null 2>&1; then
          git worktree add "${repo}@${wtbranch}" "${wtbranch}"
        else
          printf "error: branch named %s not present in repo %s\n" "${wtbranch}" "${rrepo}" >&2
          return 1
        fi
      fi
    fi
  fi

  if ! cd "${cdrepo}"; then
    printf "error: couldn't cd to checkout %s\n" "${cdrepo}" >&2
    return 1
  fi

  # If we didn't chdir() to the ${repo} let user know.
  if [ "${ocwd}" = "$(pwd)" ] && [ "$(pwd)" != "${repo}" ]; then
    printf "error: couldn't git clone %s to %s\n" "${rrepo}" "${repo}" >&2
    return 1
  fi

  # Otherwise act like cd and print out the dir we're in to stderr
  printf "%s\n" "$(pwd)" | sed -e "s|$HOME|~|" >&2
}

mt() {
  try_git "https://git.mitchty.net/${1}" "${2:-}"
}

gi() {
  try_git "https://github.com/${1}" "${2:-}"
}

bb() {
  try_git "https://bitbucket.org/${1}" "${2:-}"
}

# Get the default git branch name from a remote without cloning it. If ran in an
# existing repo it will return that repos data
gitdefbranch() {
  local remote=
  if [ $# -eq 0 ]; then
    # This is only valid when we're in a git repo already, note a bare/local
    # git repo could fail here, future mitch problem its such an edge case
    # i'm not concerned.
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      printf "fatal: gitdefbranch requires an argument to a remote when run outside of a git repo\n" >&2
      return 1
    fi
  else
    remote=${1?first arg must be a git repo}
  fi
  # If I quote here if ${remote} is null I get '' which is wrong
  #shellcheck disable=SC2086
  lsremote=$(git ls-remote ${remote} 2> /dev/null)
  headcommit=$(echo "${lsremote}" | ${AWK} '/HEAD$/ {print $1}')
  primary=$(echo "${lsremote}" | ${AWK} '!/HEAD/ && !/tag/ && /^'"${headcommit}/"' {print $2; exit}')
  echo "${primary}" | sed -e 's|refs/heads/||g'
}

# TODO Shamelessly copy/pasting from try_git, future me figure out a way to bridge the two
try_hg() {
  # assume https if input doesn't contain a protocol string :// otherwise treat
  # it as golden and let hg complain or not
  uri="${1}"
  uproto=$(printf "%s" "${uri}" | ${GREP} '://' > /dev/null 2>&1 && printf "%s" "${uri}" | sed -e 's|[:]\/\/.*||g')
  shift
  proto=${uproto:-https}
  defbranches="${1:-master main shenanigans}"
  shift > /dev/null 2>&1
  # For wrapper functions, allow destination to be an env var iff unset and
  # nonnull and $3 is present use $3 or as a fallback use $HOME/src
  destination=${DEST:-${1:-$HOME/src/pub}}

  hg_dir=$(printf "%s" "${uri}" | sed -e 's|.*[:]\/\/||g')
  rrepo="${proto}://${hg_dir}"

  # strip user@, :NNN from input uri's
  repo="${destination}/"$(printf "%s" "${hg_dir}" \
    | sed -e 's|.*\@||g' \
    | sed -e 's|\:[[:digit:]]\{1,\}\/|/|g' \
    | tr -d '~')

  # Loop through the def(ault)branches looking for a git repo to clone
  ocwd=$(pwd)
  # For this function who cares about these warnings
  # shellcheck disable=SC2116 disable=SC2086 disable=SC2034
  for branch in $(echo ${defbranches}); do
    # If we hg clone(d) and/or changed to that dir already, don't bother
    # looping, just break
    [ "${ocwd}" != "$(pwd)" ] && break

    if [ ! -d "${repo}" ]; then
      if hg identify "${rrepo}" > /dev/null 2>&1; then
        install -dm755 "${repo}"
        printf "hg clone %s %s\n" "${rrepo}" "${repo}" >&2
        hg clone "${rrepo}" "${repo}" || rmdir "${repo}"
      else
        printf "%s doesn't look to be an hg repository\n" "${rrepo}" >&2
        return 1
      fi
    fi

    # TODO: does hg support workdirs like git? for now whatever
    # Treat branch(es) "master" and "main" as special branches we don't treat
    # as workdir clone directories.
    # if [ "${branch}" != "master" ] && [ "${branch}" != "main" ]; then
    #   wtdir="${repo}@${branch}"
    #   if [ ! -d "${wtdir}" ]; then
    #     if git branch -r --list 'origin/*' | ${GREP} -E "^\s+origin/${branch}$" > /dev/null 2>&1; then
    #       git worktree add "${repo}@${branch}" "${branch}"
    #     else
    #       printf "%s at branch %s not present in repo %s\n" "${wtdir}" "${branch}" "${rrepo}"  >&2
    #       return 1
    #     fi
    #   fi

    #   # shellcheck disable=SC2164
    #   cd "${wtdir}"
    # fi

    if [ -d "${repo}" ]; then
      # shellcheck disable=SC2164
      cd "${repo}"
    fi
  done

  # If we didn't chdir() to the ${repo} let user know.
  if [ "${ocwd}" = "$(pwd)" ] && [ "$(pwd)" != "${repo}" ]; then
    printf "error: couldn't hg clone %s to %s\n" "${rrepo}" "${repo}" >&2
    return 1
  fi

  # Otherwise act like cd and print out the dir we're in to stderr
  printf "%s\n" "$(pwd)" | sed -e "s|$HOME|~|" >&2
}

# Wrapper functions to call whatever into a different prefix
# aka gi foo/bar -> ~/src/github.com/pub/foo/bar
# wrk gi foo/bar -> ~/src/github.com/wrk/foo/bar
# prv gi foo/bar -> ~/src/github.com/prv/foo/bar
#
# Note: this then means can't call them with the final arg for say gh/bb
wrk() {
  CATEGORY=wrk DEST="${HOME}/src/${0}" "$@"
}

prv() {
  CATEGORY=prv DEST="${HOME}/src/${0}" "$@"
}

# To be lazy
orgprv() {
  prv mt org-mode/private
}

orgpub() {
  mt org-mode/public
}

# Portably generate a random integer, can't depend on $RANDOM everywhere,
# especially since I am not a fan of the bash.
randint() {
  local floor="${1:-1}"
  shift > /dev/null 2>&1
  local ceil="${1:-10}"
  ${OD} -An -N2 -i /dev/urandom | ${AWK} -v f="${floor}" -v c="${ceil}" '{print (f + ($1 % (c - f)))}'
}

# Just a convenient way to do a random sleep
rsleep() {
  #shellcheck disable=SC2086
  sleep "$(randint ${1-30})"
}

# Because stuff sometimes fails, retry Until Success, this is just a silly
# wrapper around until/sleep but I do it so often...
us() {
  hookinit "$@"
  until "$@"; do
    hookiter "$@"
    sleep "$(randint)"
  done
  hookok "$@"
}

forever() {
  while true; do
    "$@"
  done
}

# Function/thing to run in retry/randretry/backoff/us on init, can be used to
# print out a "I"m gonna do a thing message or whatever.
LIMITERINITFN=${LIMITERINITFN-}

# Used by the functions to call some other function on retry/etc... startup, for
# stuff like an announcement "i'm about to do a thing" printf
#
# will send the entire arguments
hookinit() {
  if [ -n "${LIMITERINITFN}" ]; then
    eval "${LIMITERINITFN} $*"
  fi
}

# Function/thing to call on each iteration
LIMITERFN=${LIMITERFN-}

# Each time a retry iterates we call this with the iteration data and pass in the function that called it too
#
# Similar to the init hook, aka retry limit iter args...
hookiter() {
  if [ -n "${LIMITERFN}" ]; then
    eval "${LIMITERFN} $*"
  fi
}

# Function/thing to call on failure
LIMITERFAILFN=${LIMITERFAILFN-}

hookfail() {
  if [ -n "${LIMITERFAILFN}" ]; then
    eval "${LIMITERFAILFN} $*"
  fi
}

# Function/thing to call on success
LIMITEROKFN=${LIMITEROKFN-}

hookok() {
  if [ -n "${LIMITEROKFN}" ]; then
    eval "${LIMITEROKFN} $*"
  fi
}

# Retry N times some command/thing, requires the limit to be first arg.
#
# On success running thing within the limit set, returns 0
# otherwise returns limit reached so that failures can propogate.
retry() {
  hookinit "$@"

  limit=${1-1}
  shift

  iter=0
  until [ "${iter}" -ge "${limit}" ] || "$@"; do
    iter=$((iter + 1))
    hookiter "${0}" "${limit}" "${iter}" "$@"
  done

  if [ "${iter}" = "${limit}" ]; then
    hookfail "${0}" "${limit}" "${iter}" "$@"
    return "${limit}"
  fi

  hookok "${0}" "${limit}" "${iter}" "$@"
  return 0
}

# Similar to the above but will sleep between retries a random integer value
# from 0 to the limit passed between each run.
randretry() {
  hookinit "$@"

  limit=${1-1}
  shift
  interval=${1-5}
  shift

  iter=0
  until [ "${iter}" -ge "${limit}" ] || "$@"; do
    iter=$((iter + 1))
    # For this use case the quotes aren't helpful here
    #shellcheck disable=SC2046 disable=SC2086
    nap="$(randint ${interval})"
    hookiter "${0}" "${limit}" "${nap}" "$@"
    sleep "${nap}"
  done

  if [ "${iter}" = "${limit}" ]; then
    hookfail "${0}" "${limit}" "${iter}" "$@"
    return "${limit}"
  fi

  hookok "${0}" "${limit}" "${iter}" "$@"
  return 0
}

# Also like the above backoff between tries. Note this acts like a circuit
# breaker, the backoff is simply a doubling of the sleep between runs, the
# backoff limit just determines when the backoff is reset back to 1.
#
# Put another way, if we say backoff 100 10, what we're saying is that when the
# limit has doubled past 10, it gets reset to 1 for any further tries until it
# again goes above 10 and repeats. The backoff limit is simply to prevent
# exp scaling to obscene sleeps unless someone *really* wants it.
backoff() {
  limit=${1-1}
  shift
  breaker=${1-10}
  shift

  iter=0
  curr=1
  until [ "${iter}" -ge "${limit}" ] || "$@"; do
    iter=$((iter + 1))
    curr=$((curr * 2))

    if [ "${curr}" -ge "${breaker}" ]; then
      curr=1
    fi

    sleep "${curr}"
  done

  if [ "${iter}" = "${limit}" ]; then
    return "${limit}"
  fi
  return 0
}

# Encompass the nonsense behind sed -e ... -i '' /some/file between bsd and non bsd sed
_sed_inplace_once_memo=false

_sed_inplace_once() {
  unset SED_NEEDS_WHITESPACE || :
  if ! ${_sed_inplace_once_memo}; then
    _sed_inplace_once_tmp=$(mktemp -t sedXXXXXXXX > /dev/null 2>&1)
    if ${SED:-sed} -e 's/foo/bar/g' -i'' "${_sed_inplace_once_tmp}" > /dev/null 2>&1; then
      SED_NEEDS_WHITESPACE=
    fi
    rm -f "${_sed_inplace_once_tmp}"
    _sed_inplace_once_memo=true
  fi
}

# For unit tests only to make sure we're calling what we expect to
_sut_sed_inplace() {
  _sed_inplace_once
}

# Cause bsd/gnu sed differ in -i/inplace semantics/arg parsing
#
# macos/bsd sed needs -i '' (note the space!)
# gnu/busybox sed require -i'' (note no space!)
#
# So abuse eval/param expansion to make a portable-er/ish wrapper
sed_inplace() {
  _sut_sed_inplace
  #shellspec disable=SC2119
  ${SED?} -i${SED_NEEDS_WHITESPACE:+ }'' "$@"
}

# Command not found, just a silly wrapper around command to cover cases where
# TODO: finish this pos or just abandon the idea entirely
# command -v thing fails to make tests simpler.
# cnf() {
# }

DEPLOY="${DEPLOY:-$(command -v deploy || echo deploy)}"
DEPLOYOPTS="${DEPLOYOPTS:-}"
DEPLOYACTOPTS="${DEPLOYACTOPTS:-}"
_DEPLOYOPTS=""
_DEPLOYACTOPTS=""

# Simple wrapper to just make defining/using boolean flake options in
# functions ez pz lemon squeezy
_flake_boolean_opt() {
  opt="${1?first arg must be flake input name}"
  shift
  val="${1?second arg must be the boolean value}"

  printf " --override-input %s github:boolean-option/%s" "${opt}" "${val}"
}

# Deploy to localhost in deploy-rs section (off by default)
withlocalhost() {
  _DEPLOYACTOPTS="${_DEPLOYACTOPTS} $(_flake_boolean_opt with-localhost true)"
  "$@"
}

# Deploy with local nix cache off (on by default)
withouthomecache() {
  _DEPLOYACTOPTS="${_DEPLOYACTOPTS} $(_flake_boolean_opt with-homecache false)"
  "$@"
}

deploy() {
  #shellcheck disable=SC2086
  ${DEPLOY} ${_DEPLOYOPTS} "$@" ${_DEPLOYACTOPTS}
  rc=$?
  _DEPLOYOPTS=""
  _DEPLOYACTOPTS=""
  return $?
}

norollback() {
  _DEPLOYOPTS="${_DEPLOYOPTS} ${DEPLOYOPTS} --auto-rollback false "
  "$@"
}

# Abuse ^^^ to make it ez pz to do a deploy when out and about with
# laptop.
mobiledeploy() {
  withlocalhost withouthomecache "$@"
}

# Simple wrapper function to do a deploy with checks and
# --dry-activate so that nothing of substance happens if anything is
# amiss there.
deploytest() {
  host="${1?need a hostname string to test deployment on}"
  shift
  #shellcheck disable=SC2086
  eval ${DEPLOY} -ds --dry-activate -- ".#${host}" -L --show-trace ${_DEPLOYACTOPTS}
}

# like ^^^ but mostly without the dry-activate switch and -d to run checks
deployhost() {
  host="${1?need a hostname string to run a deployment}"
  shift
  #shellcheck disable=SC2086
  eval ${DEPLOY} -s ${_DEPLOYOPTS} ${DEPLOYOPTS} -- ".#${host}" -L --show-trace ${_DEPLOYACTOPTS} ${DEPLOYACTOPTS}
}

deploytestedhost() {
  host="${1?need a hostname string to run a tested deployment}"
  shift
  #shellcheck disable=SC2086
  deploytest "${host}" && deployhost "${host}"
}

# To make other runtime stuff simpler, note if command -v fails we just "assume"
# we can use the bare program name. That may not be valid though. But given i'm
# using this in systemd minimal startup environments not sure the best option,
# until they're used its not a problem and at that point things will fail on
# exec() of ssh anyway so not a huge loss with an rc 127 at that point.
SED="${SED:-$(command -v sed || echo sed)}"
SSH="${SSH:-$(command -v ssh || echo ssh)}"
SCP="${SCP:-$(command -v scp || echo scp)}"
SSHOPTS="${SSHOPTS--o LogLevel=quiet}"

# Going to start (ab)using the V to control verbose ish output not in logging
# frameworks.

# Allow local usage for this stuff
_s_defaultfile="${_s_defaultfile:-${HOME:-~}/.ssh/sshpass}"

#
_s() {
  local cmd="$1"
  shift

  # I'm abusing assignment here
  #shellcheck disable=SC2155,SC2046
  local fullcmd="${SSH?}"
  if [ "${cmd}" = "scp" ]; then
    fullcmd="${SCP?}"
  fi
  #shellcheck disable=SC2155,SC2046
  local host=$(_s_host "$@")
  #shellcheck disable=SC2155,SC2046
  local wrapcommand=$(_s_wrapcmd "${host}")

  if [ "${wrapcommand}" = "" ]; then
    ${fullcmd} "$(_yolo)" "$@"
  else
    #shellcheck disable=SC2155,SC2046
    local wrapargs=$(_s_args "${fullcmd}")

    # Meh, this is a boolean for me...
    #shellcheck disable=SC2086
    [ -n "${V}" ] && echo "${wrapcommand} ${wrapargs} $*" | sed -e 's/^ //g' >&2
    eval "${wrapcommand} ${wrapargs} $*"
  fi
}

# Helper function to extract out the hostname or whatever looks to be the
# hostname from the _s (ssh|scp) blah... string
_s_host() {
  local hascolon=false
  local hasat=false

  if echo "$@" | ${GREP} '@' > /dev/null 2>&1; then
    hasat=true
  fi
  if echo "$@" | ${GREP} ':' > /dev/null 2>&1; then
    hascolon=true
  fi
  if $hascolon && $hasat; then
    echo "$@" | ${AWK} -F'@' '{print $NF}' | sed -e 's/[:].*//g' | ${AWK} '{print $NF}'
  elif $hascolon; then
    echo "$@" | sed -e 's/[:].*//g' | ${AWK} '{print $NF}'
  elif $hasat; then
    echo "$@" | ${AWK} -F'@' '{print $NF}' | ${AWK} '{print $1}'
  else
    # skip anything starting with - as its an argument most likely use first non - word
    #shellcheck disable=SC2068
    for x in $@; do
      if ! echo "${x}" | ${GREP} -q '^-'; then
        echo "$x" | ${AWK} '{print $1}'
        break
      fi
    done
  fi
}

_s_args() {
  local cmd="$1"
  shift
  local filename="${_s_defaultfile}"

  echo "${cmd}" "$(_yolo) -F ${filename}"
}

_s_wrapcmd() {
  local host="$1"

  # I'm abusing assignment here
  #shellcheck disable=SC2155,SC2046
  local hostcmd=$(${GREP} -A2 -E "^Host ${host}" ~/.ssh/sshpass | ${AWK} '/^  LocalCommand/ {$1=""; print $0}')
  if [ -z "${hostcmd}" ]; then
    hostcmd=$(${GREP} -A1 -E "^Hostname ${host}" ~/.ssh/sshpass | ${AWK} '/^  LocalCommand/ {$1=""; print $0}')
  fi
  echo "${hostcmd}"
}

# Add host (or alias whatever...) to ~/.ssh/sshpass
_s_addhost() {
  host="${1?first arg needs to be the full hostname}"
  shift
  alias="${1?the shorter alias for the host}"
  shift
  password="${1?second arg needs to be the password}"

  # First remove any entry that might already exist
  # if [ -f "${_s_defaultfile}" ]; then
  # TODO: fixme
  #sed_inplace -n "/^#BEGIN_${alias}/,/^#END_${alias}/d" "${_s_defaultfile}"
  # fi

  cat >> "${_s_defaultfile}" << FIN
#BEGIN_${alias}
Host ${alias}
  Hostname ${host}
  LocalCommand sshpass -p "${password}"
  ControlMaster auto
  LogLevel quiet
  UserKnownHostsFile ${_s_defaultfile}-known-hosts
#END_${alias}
FIN
}

_yolo() {
  printf "%s" "${SSHOPTS-}${SSHOPTS:+ }-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
}

yolo() {
  # Non issue in this instance, we've unit tests to prove the behavior is ok
  #shellcheck disable=SC2155 disable=SC2030
  (
    export SSHOPTS="$(_yolo)"
    "$@"
  )
}

# Bitwarden cli wrapper stuff to make it usable as a cli and not a thing that
# just yeets json.... such a crap cli ux.
bw_items() {
  bw list items --search "$*"
}

# easier way to use caffeinate -sid...
nosleep() {
  #shellcheck disable=SC2119
  onmac caffeinate -sid "$@"
}

# TODO: pick a name, this is the lazy refusal to make a name option
wtf() {
  action="${1?first arg must be an action rebuild or site-update}"
  shift

  # Default site update list of stuff to update and the order to do so in

  rc=0

  prefix=""

  #shellcheck disable=SC2119
  if [ "Darwin" = "$(${UNAME} -s)" ]; then
    prefix="caffeinate -sid"
  fi

  case "${action}" in
    rebuild)
      eval "${prefix} ${action} $*"
      rc=$?
      ;;
    site-update)
      eval "${prefix} ${action} $*"
      rc=$?
      ;;
    *)
      printf "fatal: action must be rebuild or site-update not: %s\n" "${action}" >&2
      return 1
      ;;
  esac

  # abuse notify/say so I can hear if something went sideways on macos.
  #shellcheck disable=SC2119
  if [ "Darwin" = "$(${UNAME} -s)" ]; then
    if [ "${rc}" -gt 0 ]; then
      notify failed "${action}" &
      say "${action}" "failed" &
    else
      notify 'done' "${action}" &
      say "${action}" 'done' &
    fi
    wait
  fi
  return ${rc}
}

# A simple file rotation scheme, rotate N times for file(s).
#
# Basically rm file.N mv file.N-1 file.N .... then for file -> file.0 copy but
# then truncate file.
rotatelog() {
  lim="${1:?Need a limit to support}"
  shift

  for file in "$@"; do
    idx=${lim}

    until [ "${idx}" -eq 0 ]; do
      prev=$((idx - 1))
      prevfile="${file}.${prev}"
      if [ -e "${prevfile}" ] && [ -n "${prevfile}" ]; then
        mv "${file}.${prev}" "${file}.${idx}"
      fi
      idx=$((idx - 1))
      if [ "${idx}" -eq 0 ] && [ -n "${file}" ]; then
        cp "${file}" "${file}.0"
        : > "${file}"
      fi
    done
  done
}

# Spit out a directory path that is:
# - Unique
# - based on path/$PWD
# - Also uses the host to segregate paths
#
# The premise here is to get stuff out of /tmp and into ~/src/tmp so that I can
# sync things if needed and keep stuff like cargo build artifacts out of the
# $PWD
#
# This function is intended to be portable and usable for other things too.
uniq_tmpdir() {
  local label="${1:-unknown}"
  local base="${TMPDIR:-/tmp}"
  local thishost="${HOST:-$(uname -n)}"
  #shellcheck disable=SC2046,SC2155
  local hash=$(echo "${PWD}" | sha1sum | head -c40)
  # TODO portable-ize this to use sed prolly
  local tmppath="${PWD//[^a-zA-Z0-0]/-}"

  printf "%s/uniq/%s" "${base}" "${thishost}"

  if [ "${label}" != "unknown" ]; then
      printf "/%s" "${label}"
  fi

  printf "/%s%s" "${hash}" "${tmppath}"
}

# Make abusing .patch files from github or locally easier... cause I'm a lazy jerk
maybe_patch() {
  input="$(cat /dev/stdin)"
  patchargs=${patchargs:--p1}

  # If I quote this if there are multiple args it will be "--foo --bar" vs
  # --foo --bar so NOOOOOO SHELLCHECK I am not quoting this ffs.
  #shellcheck disable=SC2086
  if echo "${input}" | patch -R -s -f --dry-run ${patchargs}; then
    printf "patch already applied\n" >&2
  else
    echo "${input}" | patch ${patchargs}
  fi
}

# Wrapped entr to handle when the directory gets updated and it exits and just
# restart using the last files input, also handle if/when you control-c (rc >
# 128 basically assuming a non crap non posix compliant exec() shell should be
# rc 130) Pass the stuff to watch on stdin and args are what is passed to entr
#
# Added ability to specify command to run via WENTR env var, this will append to
# whatever was passed in on stdin if anything. This should allow new files/dirs
# to get detected on the fly by allowing a command to be used to detect them.
wentr() {
  #shellcheck disable=SC2155
  if [ ! -t 0 ]; then
    local files="$(cat /dev/stdin)"
  else
    local files=""
  fi
  while [ $? -le 128 ]; do
    sleep 1
    local union="${files}"
    if [ -n "${WENTR}" ]; then
      #shellcheck disable=SC2046,SC2086,SC2155
      local new=$(eval ${WENTR})
      union="${union}\n${new}"
    fi
    echo "${union}" | entr -crznpad "$@"
  done
}
