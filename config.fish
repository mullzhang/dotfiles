# PATH
set -x PATH "/usr/local/bin" $PATH
set -x PATH "/usr/local/sbin" $PATH
set -x PATH "/usr/local/opt/openssl/bin" $PATH
set -x PATH "/usr/local/opt/ruby/bin" $PATH

# anyenv
set -x PATH $HOME/.anyenv/bin $PATH
eval (anyenv init - | source)

# Flutter
set -x PATH $HOME/dev/flutter_dev/flutter/bin $PATH

# Github CLI
eval (gh completion -s fish| source)

# Conda
source (conda info --root)/etc/fish/conf.d/conda.fish

# OpenJDK
set -g fish_user_paths "/usr/local/opt/openjdk/bin" $fish_user_paths

##########
# alias
alias ls "ls -aG"
alias rm "rm -i"
alias cp "cp -i"
alias mv "mv -i"
alias mkdir "mkdir -p"

# git
# alias g 'git'
alias ga 'git add'
alias gd 'git diff'
alias gs 'git status'
alias gps 'git push'
alias gb 'git branch'
alias gst 'git status'
alias gco 'git checkout'
alias gf 'git fetch'
alias gpl 'git pull'
alias gc 'git commit'
alias gl 'git log'

# jupyter notebook
alias jn 'jupyter notebook'

# jupyter lab
alias jl 'jupyter lab'

# ghq
alias g 'cd (ghq root)/(ghq list | peco)'

# hub
alias gp 'hub browse (ghq list | peco | cut -d "/" -f 2,3)'

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

# peco
function ph
    if test (count $argv) = 0
        set peco_flags --layout=bottom-up
    else
        set peco_flags --layout=bottom-up --query "$argv"
    end

    history|peco $peco_flags|read foo
    
    if [ $foo ]
        commandline $foo
    else
        commandline ''
    end
end

function pz
    set -l query (commandline)

    if test -n $query
      set peco_flags --query "$query"
    end

    z -l | peco $peco_flags | awk '{ print $2 }' | read recent
    if [ $recent ]
        cd $recent
        commandline -r ''
        commandline -f repaint
    end
end

function fish_user_key_bindings
    bind \cr ph
    bind \ce pz
end

# check how many processes is running iv ssh
function topssh
    if test (count $argv) = 0
        echo 'error: wrong number of arguments'
        echo 'usage: topssh SERVER_ID'
    else
        sshauto $argv[1] '-t top -n 1'
    end
end

# ssh auto login with expect command (installed via brew)
function sshauto
    if test (count $argv) = 0
        . ~/.ssh/auto_login.fish
    else
        . ~/.ssh/auto_login.fish $argv
    end
end

# Google search
# Source: https://gist.github.com/yasny/8893315
function google
    set -l opt
    set -l str
  
    if [ -n "$argv" ]
        for o in $argv
            set str "$str+$o"
        end
  
        set str (echo $str | sed 's/^\+//')
        set opt "search?num=50&hl=en&q=$str"
    end
    open -a Google\ Chrome "http://www.google.com/$opt"
end

# AllAcronyms search
function acr
    if [ -n "$argv" ]
        open -a Google\ Chrome "https://www.allacronyms.com/$argv[1]/abbreviated"
    end
end

