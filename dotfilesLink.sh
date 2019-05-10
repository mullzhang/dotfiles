#!/bin/sh
ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/colors ~/.vim

mkdir -p ~/.vim/pack/flake8/start/
git clone https://github.com/nvie/vim-flake8.git
mv vim-flake8 ~/.vim/pack/flake8/start/
