#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
#
# General library utility functions I end up re-writing all over the damn place
# in random scripts I create. No more! Shared library it is for once.

# TODO: add tests for this in shellspec, for now just yeeted this from random
# disparate shell I have lying around.

# Portably generate a random integer, can't depend on $RANDOM everywhere,
# especially since I am not a fan of the bash.
randint() {
  awk "BEGIN{\"date +%N\"|getline rseed;srand(rseed);close(\"date +%N\");printf \"%i\n\", (rand()*${1-10})}"
}

# Because stuff sometimes fails, retry Until Success, this is just a silly
# wrapper around until/sleep but I do it so often...
us() {
  until "$@"; do
    sleep "$(randint)"
  done
}

# Silly functions to make certain filtering easier/be lazy.
nocomments() {
  grep -Ev '^[#].*'
}

squishws() {
  grep -Ev '^[[:space:]]*$'
}

hidepass() {
  grep -Evi 'password'
}

# Silly helper functions to run stuff on specific platforms only
onlinux() {
  if [ "Linux" = "$(uname -s)" ]; then
    "$@"
  fi
}

onmac() {
  if [ "Darwin" = "$(uname -s)" ]; then
    "$@"
  fi
}

# Old env related stuff, not sure if useful anymore but good examples of....
# things written in anger I guess.

# cat out a : separated env variable
# variable is the parameter
cat_env() {
  set | grep '^'"$1"'=' > /dev/null 2>&1 && eval "echo \$$1" | tr ':' '
' | awk '!/^\s+$/' | awk '!/^$/'
}

# Convert a line delimited input to : delimited
to_env() {
  awk '!a[$0]++' < /dev/stdin | tr -s '
' ':' | sed -e 's/\:$//' | awk 'NF > 0'
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
  rest=$(cat_env "$1" | awk '{if (NR!=1) {print}}' | to_env)
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
  for x in echo "$@"; do
    sed -i -e "/$x/d" ~/.ssh/known_hosts
  done
}

# Git wrapper fn used like pushd/popd in that on success, you're in a dir/checkout

try_git() {
  # assume https if input doesn't contain a protocol string :// otherwise treat
  # it as golden and let git complain or not
  uproto=$(printf "%s" "${1}" | grep '://' > /dev/null 2>&1 && printf "%s" "${1}" | sed -e 's|[:]\/\/.*||g')
  proto=${uproto:-https}
  defbranches="${2:-master main}"
  # For wrapper functions, allow destination to be an env var iff unset and
  # nonnull and $3 is present use $3 or as a fallback use $HOME/src
  destination=${DEST:=${3:=$HOME/src/pub}}

  git_dir=$(printf "%s" "${1}" | sed -e 's|.*[:]\/\/||g')
  rrepo="${proto}://${git_dir}"

  # strip user@, :NNN, and .git from input uri's
  repo="${destination}/"$(printf "%s" "${git_dir}" |
    sed -e 's/\.git$//g' |
    sed -e 's|.*\@||g' |
    sed -e 's|\:[[:digit:]]\{1,\}\/|/|g' |
    tr -d '~')

  # Loop through the def(ault)branches looking for a git repo to clone
  ocwd=$(pwd)
  # For this function who cares about these warnings
  # shellcheck disable=SC2116 disable=SC2086
  for branch in $(echo ${defbranches}); do
    # If we git clone(d) and/or changed to that dir already, don't bother
    # looping, just break
    [ "${ocwd}" != "$(pwd)" ] && break

    if [ ! -d "${repo}" ]; then
      if git ls-remote "${rrepo}" > /dev/null 2>&1; then
        install -dm755 "${repo}"
        printf "git clone %s %s\n" "${rrepo}" "${repo}" >&2
        git clone --recursive "${rrepo}" "${repo}" || rmdir "${repo}"
      else
        printf "%s doesn't look to be a git repository\n" "${rrepo}" >&2
        return 1
      fi
    fi

    # Treat branch(es) "master" and "main" as special branches we don't treat
    # as workdir clone directories.
    if [ "${branch}" != "master" ] && [ "${branch}" != "main" ]; then
      wtdir="${repo}@${branch}"
      if [ ! -d "${wtdir}" ]; then
        if git branch -r --list 'origin/*' | grep -E "^\s+origin/${branch}$" > /dev/null 2>&1; then
          git worktree add "${repo}@${branch}" "${branch}"
        else
          printf "%s at branch %s not present in repo %s\n" "${wtdir}" "${branch}" "${rrepo}" >&2
          break
        fi
      fi

      # shellcheck disable=SC2164
      cd "${wtdir}" && break
    fi

    if [ -d "${repo}" ]; then
      # shellcheck disable=SC2164
      cd "${repo}"
    fi
  done

  # If we didn't chdir() to the ${repo} let user know.
  if [ "${ocwd}" = "$(pwd)" ] && [ "$(pwd)" != "${repo}" ]; then
    printf "error: couldn't git clone %s to %s\n" "${rrepo}" "${repo}" >&2
    return 1
  fi

  # Otherwise act like cd and print out the dir we're in to stderr
  printf "%s\n" "$(pwd)" | sed -e "s|$HOME|~|" >&2
}

mt() {
  try_git "ssh://gitea@git.mitchty.net:2222/${1}" "${2:-master}"
}

gh() {
  try_git "https://github.com/${1}" "${2:-master main}"
}

bb() {
  try_git "https://bitbucket.org/${1}" "${2:-master main}"
}

# TODO Shamelessly copy/pasting from try_git, future me figure out a way to bridge the two
try_hg() {
  # assume https if input doesn't contain a protocol string :// otherwise treat
  # it as golden and let hg complain or not
  uproto=$(printf "%s" "${1}" | grep '://' > /dev/null 2>&1 && printf "%s" "${1}" | sed -e 's|[:]\/\/.*||g')
  proto=${uproto:-https}
  defbranches="${2:-master main}"
  # For wrapper functions, allow destination to be an env var iff unset and
  # nonnull and $3 is present use $3 or as a fallback use $HOME/src
  destination=${DEST:=${3:=$HOME/src/pub}}

  hg_dir=$(printf "%s" "${1}" | sed -e 's|.*[:]\/\/||g')
  rrepo="${proto}://${hg_dir}"

  # strip user@, :NNN from input uri's
  repo="${destination}/"$(printf "%s" "${hg_dir}" |
    sed -e 's|.*\@||g' |
    sed -e 's|\:[[:digit:]]\{1,\}\/|/|g' |
    tr -d '~')

  # Loop through the def(ault)branches looking for a git repo to clone
  ocwd=$(pwd)
  # For this function who cares about these warnings
  # shellcheck disable=SC2116 disable=SC2086
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
    #     if git branch -r --list 'origin/*' | grep -E "^\s+origin/${branch}$" > /dev/null 2>&1; then
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
# aka gh foo/bar -> ~/src/github.com/pub/foo/bar
# wrk gh foo/bar -> ~/src/github.com/wrk/foo/bar
# prv gh foo/bar -> ~/src/github.com/prv/foo/bar
#
# Note: this then means can't call them with the final arg for say gh/bb
wrk() {
  DEST="${HOME}/src/${0}" "$@"
}

prv() {
  DEST="${HOME}/src/${0}" "$@"
}

# To be lazy
orgprv() {
  prv mt org-mode/private
}

orgpub() {
  mt org-mode/public
}

# Retry N times some command/thing, requires the limit to be first arg.
#
# On success running thing within the limit set, returns 0
# otherwise returns limit reached so that failures can propogate.
retry() {
  limit=${1-1}
  shift

  iter=0
  until [ "${iter}" -ge "${limit}" ] || "$@"; do
    iter=$((iter + 1))
  done

  if [ "${iter}" = "${limit}" ]; then
    return "${limit}"
  fi
  return 0
}

# Similar to the above but will sleep between retries a random integer value
# from 0 to the limit passed between each run.
randretry() {
  limit=${1-1}
  shift
  interval=${1-5}
  shift

  iter=0
  until [ "${iter}" -ge "${limit}" ] || "$@"; do
    iter=$((iter + 1))
    # For this use case the quotes aren't helpful here
    #shellcheck disable=SC2046 disable=SC2086
    sleep $(randint ${interval})
  done

  if [ "${iter}" = "${limit}" ]; then
    return "${limit}"
  fi
  return 0
}

# Also like the above backoff between tries. Note this acts like a circuit
# breaker, the backoff is simply a doubling of the sleep between runs, the
# backoff limit just determines when the backoff is reset back to 1.
#
# Put another way, if we say backoff 100 10, what we're saying is that when the
# limit has doubled past 10, it gets reset to 1 for any further tries until it
# again goes above 10 and repeats. The backoff limit is simply to prevent
# doubling scaling to obscene sleeps unless someone *really* wants it.
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