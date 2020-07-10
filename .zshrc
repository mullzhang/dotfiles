export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH

# 環境変数
export LANG=ja_JP.UTF-8


# 色を使用出来るようにする
autoload -Uz colors
colors

# ヒストリの設定
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

# 単語の区切り文字を指定する
autoload -Uz select-word-style
select-word-style default
# ここで指定した文字は単語区切りとみなされる
# / も区切りと扱うので、^W でディレクトリ１つ分を削除できる
zstyle ':zle:*' word-chars " /=;@:{},|"
zstyle ':zle:*' word-style unspecified

########################################
# 補完
# 補完機能を有効にする
autoload -Uz compinit
compinit

# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ../ の後は今いるディレクトリを補完しない
zstyle ':completion:*' ignore-parents parent pwd ..

# sudo の後ろでコマンド名を補完する
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                   /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

# ps コマンドのプロセス名補完
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'


########################################
# オプション
# 日本語ファイル名を表示可能にする
setopt print_eight_bit

# beep を無効にする
setopt no_beep

# フローコントロールを無効にする
setopt no_flow_control

# Ctrl+Dでzshを終了しない
setopt ignore_eof

# '#' 以降をコメントとして扱う
setopt interactive_comments

# ディレクトリ名だけでcdする
# setopt auto_cd

# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups

# 同時に起動したzshの間でヒストリを共有する
setopt share_history

# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups

# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space

# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks

# 高機能なワイルドカード展開を使用する
setopt extended_glob

########################################
# キーバインド

# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

########################################
# Alias
alias ls='ls --color=auto'
alias ls='ls -G'
alias ll='ls -alF'
alias ll='ls -lh'
alias ll='ls -l'
alias la='ls -A'
alias la='ls -a'
alias l='ls -CF'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias grep='grep --color'
alias df='df -h'

# sudo の後のコマンドでエイリアスを有効にする
alias sudo='sudo '

# git
alias g='git'
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias gp='git push'
alias gb='git branch'
alias gst='git status'
alias gco='git checkout'
alias gf='git fetch'
alias gc='git commit'
alias gl='git log'

# alias -s
# execute scripts
alias -s py=python
alias -s rb=ruby

# brew
alias brew="PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin brew"

# open images
if [ `uname` = "Darwin" ]; then
  alias eog='open -a Preview'
fi
alias -s {png,jpg,bmp,PNG,JPG,BMP}=eog

# chrome
if [ `uname` = "Darwin" ]; then
  alias google-chrome='open -a Google\ Chrome'
fi
alias chrome='google-chrome'

alias -s html=chrome

# extract compressed files
function extract() {
  case $1 in
    *.tar.gz|*.tgz) tar xzvf $1;;
    *.tar.xz) tar Jxvf $1;;
    *.zip) unzip $1;;
    *.lzh) lha e $1;;
    *.tar.bz2|*.tbz) tar xjvf $1;;
    *.tar.Z) tar zxvf $1;;
    *.gz) gzip -d $1;;
    *.bz2) bzip2 -dc $1;;
    *.Z) uncompress $1;;
    *.tar) tar xvf $1;;
    *.arj) unarj $1;;
  esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz}=extract

# jupyter notebook
alias jn='jupyter notebook'

# pip upgrade all
alias pipug="pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs pip install -U pip"

# chrome for ipython notebook
export BROWSER=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome

# coreutils
export PATH=/usr/local/opt/coreutils/libexec/gnubin:${PATH}
export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:${MANPATH}

# Goolge Search by Google Chrome
function google() {
    local str opt
    if [ $# != 0 ]; then
        for i in $*; do
            # $strが空じゃない場合、検索ワードを+記号でつなぐ(and検索)
            str="$str${str:++}$i"
        done
        opt='search?num=100'
        opt="${opt}&q=${str}"
    fi
    open -a Google\ Chrome http://www.google.co.jp/$opt
}

# OS 別の設定
case ${OSTYPE} in
    darwin*)
        #Mac用の設定
        export CLICOLOR=1
        alias ls='ls -G -F'
        ;;
    linux*)
        #Linux用の設定
        alias ls='ls -F --color=auto'
        ;;
esac

# vim:set ft=zsh:
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/openssl/bin:$PATH"
export PATH="/usr/local/opt/ruby/bin:$PATH"

# tmux split window
function ide() {
tmux split-window -v -p 30
tmux split-window -h -p 50
}

# Python
eval "$(pyenv init -)"

# Rust
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Django
export DJANGO_SETTINGS_MODULE=mysite.settings

# Generate .gitignore
function gi() { curl -sL https://www.gitignore.io/api/$@ ;}

# Virtualenvwrapper
if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
   export WORKON_HOME=$HOME/.virtualenvs
   source /usr/local/bin/virtualenvwrapper.sh
fi
