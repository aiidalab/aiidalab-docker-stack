#!/bin/bash
set -x

# If the container is start by spawner and the home is remounted.
# The .bashrc in HOME won't be set properly.
if [[ ! -f  /home/${NB_USER}/.bashrc ]]; then
    cp /etc/skel/.bashrc /home/${NB_USER}/.bashrc
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
mkdir -p --mode=0700 /home/${NB_USER}/.ssh
if [[ ! -e /home/${NB_USER}/.ssh/known_hosts ]]; then
    touch /home/${NB_USER}/.ssh/known_hosts
fi

if [[ ! -f  /home/${NB_USER}/.ssh/id_rsa ]]; then
  # Generate ssh key that works with `paramiko`
  # See: https://aiida.readthedocs.io/projects/aiida-core/en/latest/get_started/computers.html#remote-computer-requirements
  ssh-keygen -f /home/${NB_USER}/.ssh/id_rsa -t rsa -b 4096 -m PEM -N ''
fi

# Restore restrictive permissions after a persistent home is remounted (e.g.
# Kubernetes fsGroup can add group access). Cover custom key names, preserve
# file owner permissions and leave symbolic links and their targets untouched.
if ! find -P "/home/${NB_USER}/.ssh" -type d -perm /077 -exec chmod 00700 {} +; then
    echo "Warning: Could not restrict SSH directory permissions; check ownership or read-only mounts." >&2
fi
if ! find -P "/home/${NB_USER}/.ssh" -type f -perm /077 -exec chmod go-rwx {} +; then
    echo "Warning: Could not restrict SSH file permissions; check ownership or read-only mounts." >&2
fi

# Set sshagent by source load-singlesshagent.sh script
# append the command text of source to .bashrc if the script /opt/bin/load-singlesshagen.sh is present
# and the command text is not already present in .bashrc
header="# Load singlesshagent on shell startup."
if [[ -f /opt/bin/load-singlesshagent.sh ]] && ! grep -q "${header}" /home/${NB_USER}/.bashrc; then
    cat >> "/home/${NB_USER}/.bashrc" <<- EOF

${header}
if [ -f /opt/bin/load-singlesshagent.sh ]; then
    source /opt/bin/load-singlesshagent.sh
fi
EOF
fi

# load the ssh-agent and add the default key generated
# the return code can be non-zero if the ssh-agent is not running
# which will cause the notebook to fail to start so we need to ignore the return code
source /opt/bin/load-singlesshagent.sh || true
