# plug.vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
touch ~/.tmux/.tmux.local.conf

# symbolic links
mkdir -p ~/.config/git ~/.config/mise ~/.config/mise/conf.d
mkdir -p ~/dotfiles/local

if [ ! -f ~/dotfiles/local/zshrc ]; then
  printf '%s\n' \
    '# Machine-specific zsh settings.' \
    '' \
    '# export PROJECT_ROUTES_CONFIG="$HOME/path/to/project-routes.yaml"' \
    '# export GMEET_RECORDINGS_DIR="$HOME/path/to/Meet Recordings"' \
    > ~/dotfiles/local/zshrc
fi

if [ ! -f ~/dotfiles/local/gitconfig ]; then
  printf '%s\n' \
    '# Machine-specific Git settings.' \
    '' \
    '# [user]' \
    '#   email = you@example.com' \
    '#' \
    '# [core]' \
    '#   sshCommand = ssh -i ~/.ssh/id_ed25519' \
    > ~/dotfiles/local/gitconfig
fi

if [ ! -f ~/dotfiles/local/tmux.conf ]; then
  printf '%s\n' \
    '# Machine-specific tmux settings.' \
    '' \
    '# set -g default-shell /opt/homebrew/bin/zsh' \
    > ~/dotfiles/local/tmux.conf
fi

if [ ! -f ~/dotfiles/local/vimrc ]; then
  printf '%s\n' \
    '" Machine-specific Vim settings.' \
    '' \
    '" set spell' \
    > ~/dotfiles/local/vimrc
fi

if [ ! -f ~/dotfiles/local/latexmkrc ]; then
  printf '%s\n' \
    '#!/usr/bin/env perl' \
    '' \
    '# Machine-specific latexmk settings.' \
    '' \
    "# \$pdf_previewer = 'open -ga /Applications/Skim.app';" \
    > ~/dotfiles/local/latexmkrc
fi

if [ ! -f ~/dotfiles/local/mise.toml ]; then
  printf '%s\n' \
    '# Machine-specific mise settings.' \
    '' \
    '# [env]' \
    '# PROJECT_ROUTES_CONFIG = "{{env.HOME}}/path/to/project-routes.yaml"' \
    '# GMEET_RECORDINGS_DIR = "{{env.HOME}}/path/to/Meet Recordings"' \
    > ~/dotfiles/local/mise.toml
fi

ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/.vimrc ~/.vimrc
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.gitignore_global ~/.config/git/ignore
ln -sf ~/dotfiles/.mmcp.json ~/.mmcp.json
ln -sf ~/dotfiles/mise_config.toml ~/.config/mise/config.toml
ln -sf ~/dotfiles/local/mise.toml ~/.config/mise/conf.d/local.toml
