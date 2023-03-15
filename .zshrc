# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# local file
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# zsh plugins
if [[ $(uname) =~ ^Darwin* ]]; then
    source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Alias
alias ls="ls -aG"
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -p"

# poetry
alias pt=poetry

# dart
alias dt=dart

# git
alias g=git

# python
alias py=python

# anyenv
eval "$(anyenv init -)"

# rust
export PATH="$HOME/.cargo/bin:$PATH"

# coreutils (including tac command etc)
export PATH=$PATH:/usr/local/opt.coreutils/libexec/gnubin

# alfred
# package manager
export PATH="/opt/homebrew/opt/php/bin:$PATH"
export PATH="/opt/homebrew/opt/php/sbin:$PATH"

# Functions
# tmux
function ide() {
  tmux split-window -v -p 30
  tmux split-window -h -p 50
  tmux select-pane -U
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
  curl -sL "https://www.gitignore.io/api/$1" > .gitignore
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
function peco-cdr() {
    local selected_dir="$(cdr -l | sed 's/^[[:digit:]]*[[:blank:]]*//' | peco --prompt="cdr >" --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}
zle -N peco-cdr
bindkey '^S' peco-cdr

# ghq with peco
function peco-ghq-look() {
    local selected_dir="$(ghq root)/$(ghq list | peco)"
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
}

zle -N peco-ghq-look
bindkey '^G' peco-ghq-look
