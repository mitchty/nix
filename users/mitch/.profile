# -*- mode: Shell-script; -*-
# Common .profile
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
  # assume https if input doesn't contain a protocol
  proto=https
  destination=${HOME}/src
  branch="${2:-master}"

  printf "%s\n" "${1}" | grep '://' > /dev/null 2>&1 && proto=$(echo "${1}" | sed -e 's|[:]\/\/.*||g')
  git_dir=$(echo "${1}" | sed -e 's|.*[:]\/\/||g')
  rrepo="${proto}://${git_dir}"

  # strip user@, :NNN, and .git from input uri's
  repo="${destination}/"$(echo "${git_dir}" |
    sed -e 's/\.git$//g' |
    sed -e 's|.*\@||g' |
    sed -e 's|\:[[:digit:]]\{1,\}\/|/|g' |
    tr -d '~')

  if [ ! -d "${repo}" ]; then
    if git ls-remote "${rrepo}" > /dev/null 2>&1; then
      install -dm755 "${repo}"
      echo "git clone ${rrepo} ${repo}"
      git clone --recursive "${rrepo}" "${repo}"
    else
      echo "${rrepo} doesn't look to be a git repository"
    fi
  fi

  if [ "${branch}" != "master" ]; then
    wtdir="${repo}@${branch}"
    if [ ! -d "${wtdir}" ]; then
      if git branch -r --list 'origin/*' | grep -E "^\s+origin/${branch}$" > /dev/null 2>&1; then
        git worktree add "${repo}@${branch}" "${branch}"
      else
        echo "${wtdir} branch ${branch} not present in ${rrepo}"
        return
      fi
    fi
    echo "${wtdir}" | sed -e "s|$HOME|~|"
    cd "${wtdir}" || return 126
  else
    if [ -d "${repo}" ]; then
      echo "${repo}" | sed -e "s|$HOME|~|"
      cd "${repo}" || return 126
    fi
  fi
}

mt()
{
  try_git "ssh://gitea@git.mitchty.net:2222/${1}" "${2:-master}"
}

gh()
{
  try_git "https://github.com/${1}" "${2:-master}"
}

bb()
{
  try_git "https://bitbucket.org/${1}" "${2:-master}"
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
    tmux has-session -t "$1" 2>/dev/null && tmux new-session -d -s "$1"
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

PATH="${PATH}:${HOME}/bin:${HOME}/.local/bin"
export PATH
