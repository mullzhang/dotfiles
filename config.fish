# PATH
set PATH "/usr/local/bin" $PATH
set PATH "/usr/local/sbin" $PATH
set PATH "/usr/local/opt/openssl/bin" $PATH
set PATH "/usr/local/opt/ruby/bin" $PATH

# Python
set -x PATH $HOME/.pyenv/bin $PATH
source (pyenv init - | psub)

##########
# alias
alias ls "ls -aG"
alias rm "rm -i"
alias cp "cp -i"
alias mv "mv -i"
alias mkdir "mkdir -p"

# git
alias g 'git'
alias ga 'git add'
alias gd 'git diff'
alias gs 'git status'
alias gp 'git push'
alias gb 'git branch'
alias gst 'git status'
alias gco 'git checkout'
alias gf 'git fetch'
alias gc 'git commit'
alias gl 'git log'

# jupyter notebook
alias jn 'jupyter notebook'

##########
# tmux split window
function ide
    tmux split-window -v -p 30
    tmux split-window -h -p 50
end

# generate .gitignore
function gi
    curl -sL "https://www.gitignore.io/api/$argv" > .gitignore
end

