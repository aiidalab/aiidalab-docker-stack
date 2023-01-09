#!/bin/bash

# If the container is start by spawner and the home is remounted.
# The .bashrc in HOME won't be set properly.
if [[ ! -f  /home/${NB_USER}/.bashrc ]]; then
    cat /etc/skel/.bashrc > /home/${NB_USER}/.bashrc
fi

if [[ ! -f  /home/${NB_USER}/.profile ]]; then
    cat /etc/skel/.profile > /home/${NB_USER}/.profile
fi

if [[ ! -f  /home/${NB_USER}/.bash_logout ]]; then
    cat /etc/skel/.bash_logout > /home/${NB_USER}/.bash_logout
fi

# The vim.tiny shipped with jupyter base stack start vim
# in compatible mode, by creating `.vimrc` file in user home
# make it nocompatible mode so the modern vim features is available:
# https://superuser.com/questions/543317/what-is-compatible-mode-in-vim/543327#543327
if [[ ! -f  /home/${NB_USER}/.vimrc ]]; then
    echo "set nocp" > .vimrc
fi
