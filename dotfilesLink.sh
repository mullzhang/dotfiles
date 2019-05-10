#!/bin/sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/colors ~/.vim

mkdir -p ~/.vim/pack/flake8/start/
git clone https://github.com/nvie/vim-flake8.git
cp -rf vim-flake8 ~/.vim/pack/flake8/start/
rm -rf vim-flake8
