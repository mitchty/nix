# -*- mode: Shell-script; -*-

# TODO: Do I really need this anymore? If I build node specific files with nix I
# could just customize this at the derivation level
_uname=$(uname)
_uname_n=$(uname -n)
_hostname=$(hostname)
export _uname _uname_n _hostname

# cat out a : separated env variable
# variable is the parameter
cat_env()
{
  set | grep '^'"$1"'=' > /dev/null 2>&1 && eval "echo \$$1" | tr ':' '
' | awk '!/^\s+$/' | awk '!/^$/'
}

# Convert a line delimited input to : delimited
to_env()
{
  awk '!a[$0]++' < /dev/stdin | tr -s '
' ':' | sed -e 's/\:$//' | awk 'NF > 0'
}

# Unshift a new value onto the env var
# first arg is ENV second is value to unshift
# basically prepend value to the ENV variable
unshift_env()
{
  new=$(eval "echo $2; echo \$$1" | to_env)
  eval "$1=${new}; export $1"
}

# Opposite of above, but echos what was shifted off
shift_env()
{
  first=$(cat_env "$1" | head -n 1)
  rest=$(cat_env "$1" | awk '{if (NR!=1) {print}}' | to_env)
  eval "$1=$rest; export $1"
  echo "${first}"
}

# push $2 to $1 on the variable
push_env()
{
  have=$(cat_env "$1")
  new=$(printf "%s
%s" "$have" "$2" | to_env)
  eval "$1=$new; export $1"
}

# Remove a line matched in $HOME/.ssh/known_hosts for when there are legit
# host key changes.
nukehost()
{
  for x in echo "$@"; do
    sed -i -e "/$x/d" ~/.ssh/known_hosts
  done
}

# Cheap copy function to make copying a file via ssh from one host
# to another less painful, use pipeviewer to give some idea as to progress.
sshcopy()
{
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: copy source:/file/location destination:/file/location"
  else
    srchost="$(echo "$1" | awk -F: '{print $1}')"
    src="$(echo "$1" | awk -F: '{print $2}')"
    dsthost="$(echo "$2" | awk -F: '{print $1}')"
    dst="$(echo "$2" | awk -F: '{print $2}')"
    size=$(ssh "$srchost" du -hs "$src" 2> /dev/null)
    if [ "${size}" = "" ]; then
      echo "${src} doesn't seem to exist on ${srchost}"
      return 1
    fi
    size=$(echo "${size}" | awk '{print $1}')
    echo "Copying $size to $dst"
    (ssh "${srchost}" "/bin/cat ${src}" | pv -cb -N copied - | ssh "$dsthost" "/bin/cat - > ${dst}") 2> /dev/null
  fi
}

# extract function to automate being lazy at extracting archives.
extract()
{
  if [ -f "$1" ]; then
    case ${1} in
      ,*.tar.bz2|*.tbz2|*.tbz)  bunzip2 -c "$1" | tar xvf -;;
      ,*.tar.gz|*.tgz)          gunzip -c "$1" | tar xvf -;;
      ,*.tz|*.tar.z)            zcat "$1" | tar xvf -;;
      ,*.tar.xz|*.txz|*.tpxz)   xz -d -c "$1" | tar xvf -;;
      ,*.bz2)                   bunzip2 "$1";;
      ,*.gz)                    gunzip "$1";;
      ,*.jar|*.zip)             unzip "$1";;
      ,*.rar)                   unrar x "$1";;
      ,*.tar)                   tar -xvf "$1";;
      ,*.z)                     uncompress "$1";;
      ,*.rpm)                   rpm2cpio "$1" | cpio -idv;;
      ,*)                       echo "Unable to extract <$1> Unknown extension."
    esac
  else
    print "File <$1> does not exist."
  fi
}

# Tcsh compatibility so I can be a lazy bastard and paste things directly
# if/when I need to.
setenv()
{
  export "$1=$2"
}

# Just to be lazy, set/unset the DEBUG env variable used in my scripts
debug()
{
  if [ -z "$DEBUG" ]; then
    if [ -z "$1" ]; then
      echo Setting DEBUG to "$1"
      setenv DEBUG "$1"
    else
      echo Setting DEBUG to default
      setenv DEBUG default
    fi
  else
    echo Unsetting DEBUG
    unset DEBUG
  fi
}

login_shell()
{
  [ "$-" = "*i*" ]
}

# TODO: figure out a way to concatenate things based on roles like git tmux
# etc... for now whatever.
try_git()
{
  # assume https if input doesn't contain a protocol string :// otherwise treat
  # it as golden and let git complain or not
  proto=${$(printf "%s" "${1}" | grep '://' > /dev/null 2>&1 && printf "%s" "${1}" | sed -e 's|[:]\/\/.*||g'):-https}
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

mt()
{
  try_git "ssh://gitea@git.mitchty.net:2222/${1}" "${2:-master}"
}

gh()
{
  try_git "https://github.com/${1}" "${2:-master main}"
}

bb()
{
  try_git "https://bitbucket.org/${1}" "${2:-master main}"
}

# TODO Shamelessly copy/pasting from try_git, future me figure out a way to bridge the two
try_hg()
{
  # assume https if input doesn't contain a protocol string :// otherwise treat
  # it as golden and let hg complain or not
  proto=${$(printf "%s" "${1}" | grep '://' > /dev/null 2>&1 && printf "%s" "${1}" | sed -e 's|[:]\/\/.*||g'):-https}
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

# TODO: This needed anymore for macos?
# if [ ! -e ${HOME}/.nonix ]; then
#   SSL_CERT_FILE="${HOME}/.nix-profile/etc/ssl/certs/ca-bundle.crt"
#   GIT_SSL_CAINFO=$SSL_CERT_FILE
#   export SSL_CERT_FILE
#   export GIT_SSL_CAINFO
# fi
#
#if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh # added by Nix installer

t()
{
  if [ -z "$1" ]; then
    echo "Supply a tmux session name to connect to/create"
  else
    tmux has-session -t "$1" 2>/dev/null || tmux new-session -d -s "$1"
    tmux attach-session -d -t "$1"
  fi
}

# general aliases
alias s="\$(which ssh)"
alias quit='exit'
alias cr='reset; clear'
alias a=ag
alias n=noglob
alias l=ls
alias L='ls -dal'
alias cleandir="find . -type f \( -name '*~' -o -name '#*#' -o -name '.*~' -o -name '.#*#' -o -name 'core' -o -name 'dead.letter*' \) | grep -v auto-save-list | xargs -t rm"

# Prefer less for paging duties.
if which less > /dev/null 2>&1; then
  alias T="\$(which less) -f +F"
else
  alias T="\$(which tail) -f"
fi

alias e=emacs
alias de='emacs --debug-init -nw'
alias ec=emacsclient
alias ect='emacsclient -t'
alias oec='emacsclient -n -c'
alias stope='emacsclient -t -e "(save-buffers-kill-emacs)(kill-emacs)"'
alias kille='emacsclient -e "(kill-emacs)"'

alias g=git
alias m=mosh
alias tl='tmux ls'
alias res='. ~/.profile'

# Seriously don't get how syncthing constantly breaks stuff when I only make
# changes on ONE machine.
alias watdidstbreak='find . -type f -name "*sync-conflict*" -print'

# Run nixpkgs-fmt and format things iff there are changes.
alias nfmt='find . -type f -name \*\.nix -exec sh -c "nixpkgs-fmt --check {} > /dev/null 2>&1 || nixpkgs-fmt {}" \;'

# silly function to make running deploy-rs easier
deploy() {
  (
    gh mitchty/nix
    clear
    set -e
    [ "$1" = "check" ] && nix flake check --show-trace
    if [[ "$(uname -s)" = "Linux" ]]; then
      nix run github:serokell/deploy-rs -- -s .
    else
      darwin-rebuild switch --flake .#
    fi
  )
}

# Home backup/rsync alias until I get restic working again.
alias hb='rsync -e "ssh -T -c aes128-ctr -o Compression=no -x" --exclude .cache --exclude target/debug --exclude target/release --exclude packer_cache --exclude baloo/index --delete-excluded --progress --delete -Havz $HOME root@dfs1.local:/mnt/rsync/$(uname -n)'

PATH="${PATH}:${HOME}/bin:${HOME}/.local/bin"
export PATH

# Silly helper functions to run stuff on specific platforms only
onlinux() {
  if [[ "$(uname -s)" = "Linux" ]]; then
    "$@"
  fi
}

onmac() {
  if [[ "$(uname -s)" = "Darwin" ]]; then
    "$@"
  fi
}

iso() {
  runtime=$(date +%Y-%m-%d-%H:%M:%S)

  (
    set -ex
    for x in "$@"; do
      nix build .#iso${x}
      install -dm755 img
      lnsrc="img/${x}@${runtime}.iso"
      lndst="img/${x}.iso"
      install -m444 ./result/**/*.iso ${lnsrc}
      ln -f ${lnsrc} ${lndst}
    done

    # Make sure we don't have duplicate iso files, or if we do make them hardlinks
    [ -d img ] && nix-shell -p rdfind --run 'rdfind -deterministic true -makeresultsfile false -makehardlinks true img'
  )
}

sdimg() {
  runtime=$(date +%Y-%m-%d-%H:%M:%S)

  (
    set -ex
    for x in "$@"; do
      nix build .#sd${x}
      install -dm755 img
      lnsrc="img/${x}@${runtime}.img.zst"
      lndst="img/${x}.img.zst"
      install -m444 ./result/**/*.img.zst ${lnsrc}
      ln -f ${lnsrc} ${lndst}
    done

    # Make sure we don't have duplicate iso files, or if we do make them hardlinks
    [ -d img ] && nix-shell -p rdfind --run 'rdfind -deterministic true -makeresultsfile false -makehardlinks true img'
  )
}
