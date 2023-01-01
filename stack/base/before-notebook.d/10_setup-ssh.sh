#!/bin/bash

# Make sure that the known_hosts file is present inside the .ssh folder.
mkdir -p --mode=0700 /home/${NB_USER}/.ssh && \
    touch /home/${NB_USER}/.ssh/known_hosts


if [[ ! -f  /home/${NB_USER}/.ssh/id_rsa ]]; then
  # Generate ssh key that works with `paramiko`
  # See: https://aiida.readthedocs.io/projects/aiida-core/en/latest/get_started/computers.html#remote-computer-requirements
  ssh-keygen -f /home/${NB_USER}/.ssh/id_rsa -t rsa -b 4096 -m PEM -N ''
fi

# Start the ssh-agent.
eval `ssh-agent`

# The vim.tiny shipped with jupyter base stack start vim
# in a so called compatible mode. Let's turn it off to make modern vim features available.
# https://superuser.com/questions/543317/what-is-compatible-mode-in-vim/543327#543327
if [[ ! -f /home/$NB_USER/.vimrc ]];then
  echo "set nocp" > /home/${NB_USER}/.vimrc
fi
