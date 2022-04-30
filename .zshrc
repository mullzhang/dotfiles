# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Alias
alias ls="ls -aG"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -p"

# poetry
alias poetry=pt

# dart
alias dart=dt

# git
alias g=git

# ghq
alias gcd='cd "$(ghq root)/$(ghq list | peco)"'

# jupyterlab
alias jl="jupyter lab"

# anyenv
eval "$(anyenv init -)"

# rust
export PATH="$HOME/.cargo/bin:$PATH"

# Functions
# tmux
function ide() {
  tmux split-window -v -p 30
  tmux split-window -h -p 50
  tmux select-pane -U
}

# gitignore
function gi() {
  curl -sL "https://www.gitignore.io/api/$1" > .gitignore
}

# AllAcronyms search
function acr() {
  open -a Google\ Chrome "https://www.allacronyms.com/$1/abbreviated"
}

# Goole search
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
# history with peco
function peco-history-selection() {
    BUFFER=`history -n 1 | tac  | awk '!a[$0]++' | peco`
    CURSOR=$#BUFFER
    zle reset-prompt
}

zle -N peco-history-selection
bindkey '^R' peco-history-selection

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# cdr with peco
function peco-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}

zle -N peco-cdr
bindkey '^S' peco-cdr

# ghq with peco
function peco-ghq-look () {
    local ghq_roots="$(git config --path --get-all ghq.root)"
    local selected_dir=$(ghq list --full-path | \
        xargs -I{} ls -dl --time-style=+%s {}/.git | sed 's/.*\([0-9]\{10\}\)/\1/' | sort -nr | \
        sed "s,.*\(${ghq_roots/$'\n'/\|}\)/,," | \
        sed 's/\/.git//' | \
        peco --prompt="cd-ghq >" --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd $(ghq list --full-path | grep --color=never -E "/$selected_dir$")"
        zle accept-line
    fi
}

zle -N peco-ghq-look
bindkey '^G' peco-ghq-look


# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=/Users/mull/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;
