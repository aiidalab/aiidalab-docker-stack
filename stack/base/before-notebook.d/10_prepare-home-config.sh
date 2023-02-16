#!/bin/bash

# If the container is start by spawner and the home is remounted.
# The .bashrc in HOME won't be set properly.
if [[ ! -f  /home/${NB_USER}/.bashrc ]]; then
    cp /etc/skel/.bashrc /home/${NB_USER}/.bashrc
fi

# Set sshagent by source load-singlesshagent.sh script
# append the command text of source to .bashrc if the script /opt/bin/load-singlesshagen.sh is present
# and the command text is not already present in .bashrc
if [[ -f /opt/bin/load-singlesshagent.sh ]] && ! grep -q "# Load singlesshagent on shell startup." /home/${NB_USER}/.bashrc; then
    cat >> "/home/${NB_USER}/.bashrc" <<- EOF

# Load singlesshagent on shell startup.
if [ -f /opt/bin/load-singlesshagent.sh ]; then
    source /opt/bin/load-singlesshagent.sh
fi
EOF
fi

if [[ ! -f  /home/${NB_USER}/.profile ]]; then
    cp /etc/skel/.profile /home/${NB_USER}/.profile
fi

if [[ ! -f  /home/${NB_USER}/.bash_logout ]]; then
    cp /etc/skel/.bash_logout /home/${NB_USER}/.bash_logout
fi

# The vim.tiny shipped with jupyter base stack start vim
# in compatible mode, by creating `.vimrc` file in user home
# make it nocompatible mode so the modern vim features is available:
# https://superuser.com/questions/543317/what-is-compatible-mode-in-vim/543327#543327
if [[ ! -f  /home/${NB_USER}/.vimrc ]]; then
    echo "set nocp" > .vimrc
fi

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
