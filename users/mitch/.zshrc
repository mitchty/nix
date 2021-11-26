#-*-mode: Shell-script; coding: utf-8;-*-
# zsh specific global aliases

# Need to source .profile as that is not one of the files sourced by zsh.
#
# Note: only source .profile when we're in an interactive shell
#
# TODO: should rethink what I put in .profile tbh
if [[ -o interactive ]]; then
  emulate sh
  [[ -e ~/.profile ]] && source ~/.profile
  emulate zsh
fi

# Keybindings, what few there are.
bindkey -v
bindkey '^P' push-line # Saves the current line and returns to it afterwards.

# I like my options
setopt append_history
setopt hist_reduce_blanks
setopt hist_no_store
setopt histignorespace
setopt no_hist_beep
setopt no_list_beep
setopt inc_append_history
setopt auto_menu
setopt bash_auto_list

# Options that don't need to be set.
unsetopt bad_pattern # No, don't warn me on bad file patterns kthxbai.

# The rest of the story (tm) (c) (r) in option settings.
setopt equals
setopt notify
setopt glob_dots
setopt print_exit_value # I love you zsh for this, print out non zero exits.

other_term()
{
  case $TERM in
  ,*xterm*|*rxvt*|dtterm|kterm|eterm)
    print -Pn "\e]2;%~\a"
    ;;
  sun-cmd)
    print -Pn "\e]l%~\e\\"
    ;;
  ,*)
    ;;
  esac
}

chpwd()
{
  [[ -o interactive ]] || return
  case $TERM in
  eterm-color) # getting emacs terminal to not be annoying... sucks
    print -Pn ""
    ;;
  ,*)
    if [[ $SSH_TTY != '' ]]; then
      case $ORIG_TERM in
      eterm-color)
        print -Pn ""
        ;;
      ,*)
        other_term
        ;;
      esac
    fi
    ;;
  esac
}

# Needs to be reviewed a bit.
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:*:*:processes' force-list always

# No need to setup ssh known host parsing as root, just regular users.
# This is pretty old using compctl, need to update eventually.

if [[ "$LOGNAME" != "root" ]]; then
    zmodload zsh/mathfunc
    if [[ -f "$HOME/.ssh/known_hosts" ]]; then
        hosts=(${${${${(f)"$(<$HOME/.ssh/known_hosts)"}:#[0-9]*}%%\ *}%%,*})
        zstyle ':completion:*:(ssh|scp|cssh):*' hosts $hosts
        zstyle ':completion:*:*:*:hosts-host' ignored-patterns '|1|*' loopback localhost
    fi
    zstyle ':completion:::complete*' use-cache 1

    # This really should be closer to the definition of extract.
    compctl -g '*.tar.bz2 *.tbz2 *.tbz *.tar.gz *.tgz *.bz2 *.gz *.jar *.zip *.rar *.tar *.Z *.tZ *.tar.Z' + -g '*(-/)' extract
fi

# More history options for newer zsh versions
setopt share_history
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_no_functions
setopt hist_expire_dups_first

bindkey ' ' magic-space # Complete spaces too dammit, i'm lazy.

zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*:kill:*:processes' command "ps x"
zstyle ':completion:*' menu select=2

autoload -U compinit
autoload -U colors && colors
autoload -Uz vcs_info

bindkey -e

local userat="%{$fg[blue]%}%n%(!.%{$fg[red]%}.%{$fg[blue]%})%{$reset_color%}%B@%b%{$fg[blue]%}%m%b"
local pwd="%B%~%b"
local userchar="%(!.#.$)"

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
setopt prompt_subst

precmd()
{
  [[ -d .git ]] && vcs_info
}

# +N/-N upstream info
function +vi-git-st() {
    local ahead behind
    local -a gitstatus

    ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | sed -e 's|^ *||g')
    behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | sed -e 's|^ *||g')

    (( $ahead )) && gitstatus+=( "+${ahead}" )
    (( $behind )) && gitstatus+=( "-${behind}" )

    hook_com[misc]+=${(j:/:)gitstatus}
}

# Untracked crap in the repo not covered by .gitignore?
function +vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep '??' &> /dev/null ; then
        hook_com[staged]+="%{$fg[red]%}N"
    fi
}

local branch="%{$fg[green]%}%b%c%u%{$fg[green]%}%{$reset_color%}"
zstyle ':vcs_info:*' formats "%m $branch"
zstyle ':vcs_info:*' actionformats "%a $branch"
zstyle ':vcs_info:*' stagedstr "%{$fg[blue]%}S"
zstyle ':vcs_info:*' unstagedstr "%{$fg[blue]%}M"
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-st
PROMPT="%(!.#.$) " # $ as a user # as root
RPROMPT='${vcs_info_msg_0_} ${PWD/#$HOME/~}'
