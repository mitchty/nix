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
