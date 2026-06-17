# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# local file
[ -f ~/dotfiles/local/zshrc ] && source ~/dotfiles/local/zshrc

# Alias
alias ls="ls -aG"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -p"

# git
alias g=git

# github cli
eval "$(gh completion -s zsh)"

# Docker
# Ref. https://qiita.com/kulikala/items/f736629497a974ca82cb
alias d='docker'
alias dc='docker-compose'
alias dcnt='docker container'
alias dcur='docker container ls -f status=running -l -q'
alias dexec='docker container exec -it $(dcur)'
alias dimg='docker image'
alias drun='docker container run --rm -d'
alias drunit='docker container run --rm -it'
alias dstop='docker container stop $(dcur)'

# python
alias py=python
alias ipy=ipython

# terraform
alias tf=terraform

# rust
export PATH="$HOME/.cargo/bin:$PATH"

# coreutils (including tac command etc)
export PATH="$PATH:/opt/homebrew/opt/coreutils/libexec/gnubin"

# alfred
# package manager
export PATH="/opt/homebrew/opt/php/bin:$PATH"
export PATH="/opt/homebrew/opt/php/sbin:$PATH"

# llvm
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# Functions
# tmux
function ide() {
  tmux split-window -v -l 30%
  tmux split-window -h -l 50%
  tmux select-pane -L
  tmux select-pane -U
}

function ideh() {
  tmux split-window -h -l 50%
  tmux split-window -v -l 40%
  tmux select-pane -U
  tmux select-pane -L
}

# rename session of tmux
# Ref. https://daily.belltail.jp/?p=2518
if [ ! -z $TMUX ]; then
    tmux show-options | grep "TMUX_NO_FORCE_NAME_SESSION" > /dev/null
    if [ $? -ne 0 ]; then
        SESSION_NAME=`tmux display-message -p '#S'`
        echo $SESSION_NAME | grep "^[0-9]\+$" > /dev/null
        if [ $? -eq 0 ]; then   # Not named
            /bin/echo -n "tmux session name: "
            read NAME
            if [ ! -z $NAME ]; then
                tmux rename-session $NAME
            else
                tmux set-option update-environment TMUX_NO_FORCE_NAME_SESSION=1
            fi
        fi
    fi
fi

# gitignore
function gi() {
  curl -sL "https://www.gitignore.io/api/$1" >| .gitignore
}

# AllAcronyms search
function acr() {
  open -a Google\ Chrome "https://www.allacronyms.com/$1/abbreviated"
}

# Google search
# ref: https://osa.hatenablog.jp/entry/2020/02/24/121725
function google() {
  local str opt
  if [ $# != 0 ]; then
    for i in $*; do
      str="$str${str:++}$i"
    done
    opt='search?num=100'
    opt="${opt}&q=${str}"
  fi
  open -a Google\ Chrome http://www.google.co.jp/$opt
 }

# useful functions with peco
# ref: https://qiita.com/reireias/items/fd96d67ccf1fdffb24ed
bindkey -e

# history with peco
# tac: https://formulae.brew.sh/formula/coreutils
# peco: https://formulae.brew.sh/formula/peco
function peco-history() {
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history
bindkey '^R' peco-history

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# dotfiles
alias dots='git -C ~/dotfiles status -sb'
alias dotsync='git -C ~/dotfiles pull --rebase --autostash origin main'

function _dotfiles_status_on_cd() {
  local repo="$HOME/dotfiles"

  [[ "$PWD" == "$repo" || "$PWD" == "$repo"/* ]] || return

  git -C "$repo" fetch --quiet origin 2>/dev/null

  local msg=()
  [[ -n "$(git -C "$repo" status --porcelain)" ]] && msg+=("dirty")

  local counts ahead behind
  counts="$(git -C "$repo" rev-list --left-right --count HEAD...origin/main 2>/dev/null)" || return
  read ahead behind <<< "$counts"

  (( ahead > 0 )) && msg+=("ahead:$ahead")
  (( behind > 0 )) && msg+=("behind:$behind")

  (( ${#msg[@]} > 0 )) && print -P "%F{yellow}dotfiles:%f ${msg[*]}"
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd _dotfiles_status_on_cd

# cdr with peco
function peco-cdr() {
    local selected_dir="$(cdr -l | sed 's/^[[:digit:]]*[[:blank:]]*//' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}

zle -N peco-cdr
bindkey '^S' peco-cdr

# bdr with peco
function peco-bdr() {
    local dir
    dir=$(echo ${PWD#$HOME} | awk 'BEGIN{FS=OFS="/"} {for (i=NF; i>1; i--) print substr($0, 1, index($0,$i) + length($i) - 1)}' | peco --prompt "bdr >")
    if [ -n "$dir" ]; then
        BUFFER="cd ${HOME}${dir}"
        zle accept-line
    fi
}

zle -N peco-bdr
bindkey '^B' peco-bdr

# ghq with peco
# Ref. https://www.mizdra.net/entry/2025/11/29/235449
function peco-ghq() {
  local ghq_root="$(ghq root)"
  local selected_dir=$(find $ghq_root -mindepth 3 -maxdepth 3 -type d | sed "s|$ghq_root/||" | peco --query "$LBUFFER")
  if [[ -n "$selected_dir" ]]; then
    BUFFER="cd $ghq_root/$selected_dir"
    zle accept-line
  fi
  zle redisplay
}

zle -N peco-ghq
bindkey '^G' peco-ghq

# gh browse with peco
function peco-gh-browse() {
    local selected_dir="$(ghq list | peco --prompt 'gh browse >' | cut -d '/' -f 2,3)"
    if [ -n "$selected_dir" ]; then
        BUFFER="gh browse -R ${selected_dir}"
        zle accept-line
    fi
}

zle -N peco-gh-browse
bindkey '^Z' peco-gh-browse

# vscode with peco
function peco-code() {
    local selected_dir="$(cdr -l | sed 's/^[[:digit:]]*[[:blank:]]*//' | peco --prompt="code >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="code ${selected_dir}"
        zle accept-line
    fi
}

zle -N peco-code
bindkey '^V' peco-code

# cd to a direct child folder with peco
function peco-open-folder() {
    local base_dir="${FOLDER_OPENER_BASE:-}"
    if [[ -z "$base_dir" || ! -d "$base_dir" ]]; then
        echo "Set FOLDER_OPENER_BASE to a directory."
        return 1
    fi

    local selected_name
    selected_name="$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -f | peco --prompt="folder >" --query "${1:-${LBUFFER:-}}")"
    if [[ -n "$selected_name" ]]; then
        if [[ -n "${WIDGET:-}" ]]; then
            BUFFER="cd ${(q)base_dir}/${(q)selected_name}"
            zle accept-line
        else
            cd "$base_dir/$selected_name"
        fi
    fi

    zle redisplay 2>/dev/null || true
}

zle -N peco-open-folder
bindkey '^O' peco-open-folder

# mise with peco
# Ref. https://zenn.dev/rakuten_tech/articles/mise-peco-task-runner-workflow
peco-mise () {
  local selected
  selected=$(mise tasks 2>/dev/null | peco --prompt "mise task>" --initial-filter Fuzzy)
  if [[ -n "$selected" ]]; then
    local task_name
    task_name=$(echo "$selected" | awk '{print $1}')
    mise tasks "$task_name"
    print -z "mise run ${task_name}"
  fi
}

zle -N peco-mise
bindkey '^T' peco-mise

# Create a GitHub repository, clone it with ghq, and cd into it.
#
# Usage:
#   ghcr <repo|owner/repo>
#
# Examples:
#   ghcr my-new-repo
#   ghcr my-org/my-new-repo
function ghcr() {
  local repo="$1"
  local repo_path
  local owner

  if [[ -z "$repo" ]]; then
    echo "Usage: ghcr <repo|owner/repo>"
    return 2
  fi

  if [[ "$repo" == */* ]]; then
    repo_path="$repo"
  else
    owner="$(gh api user --jq .login)" || return
    repo_path="$owner/$repo"
  fi

  gh repo create "$repo_path" --private || return
  ghq get -p "github.com/$repo_path" || return
  cd "$(ghq root)/github.com/$repo_path" || return
}

# agent-safehouse
SAFEHOUSE_APPEND_PROFILE="$HOME/.config/agent-safehouse/local-overrides.sb"

safe() {
  local wt git_dir common_dir args=()
  wt="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
  git_dir="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"

  args+=(--workdir="$wt")

  if [[ -n "$git_dir" && "$git_dir" != "$wt/.git" ]]; then
    args+=(--add-dirs="$git_dir")
  fi
  if [[ -n "$common_dir" && "$common_dir" != "$git_dir" ]]; then
    args+=(--add-dirs="$common_dir")
  fi

  safehouse \
    "${args[@]}" \
    --append-profile="$SAFEHOUSE_APPEND_PROFILE" \
    -- "$@"
}

# Vim to open files as utf-8 (for SpecStory)
# alias vimutf8="vim -c 'edit ++enc=utf-8 ++bad=?'"
vimutf8() {
  vim -c 'set nomore' -c 'edit ++enc=utf-8 ++bad=?' "$@"
}

# mkdir and cd
function mkcd() {
  if [[ -z "$1" ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}

# Added by APM runtime setup
export PATH="$HOME/.apm/runtimes:$PATH"
