#!/bin/bash

# Make sure that the known_hosts file is present inside the .ssh folder.
mkdir -p --mode=0700 /home/${NB_USER}/.ssh && \
    touch /home/${NB_USER}/.ssh/known_hosts


if [[ ! -f  /home/${NB_USER}/.ssh/id_rsa ]]; then
  # Generate ssh key that works with `paramiko`
  # See: https://aiida.readthedocs.io/projects/aiida-core/en/latest/get_started/computers.html#remote-computer-requirements
  ssh-keygen -f /home/${NB_USER}/.ssh/id_rsa -t rsa -b 4096 -m PEM -N ''
fi

# Set by source load-singlesshagent.sh script
echo $'\n# Load singlesshagent on shell startup.
if [ -f /opt/bin/load-singlesshagent.sh ]; then
   . /opt/bin/load-singlesshagent.sh
fi\n' >> "/home/${NB_USER}/.bashrc"

# Start the ssh-agent.
eval `ssh-agent`
