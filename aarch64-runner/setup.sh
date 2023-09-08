#!/bin/bash
set -ex

GITHUB_RUNNER_USER="runner-user"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"


echo "Setting up runner-user, who will run GitHub Actions runner"
adduser --disabled-password --gecos "" ${GITHUB_RUNNER_USER}
mkdir /home/${GITHUB_RUNNER_USER}/.ssh/
cp "/home/${SUDO_USER}/.ssh/authorized_keys" "/home/${GITHUB_RUNNER_USER}/.ssh/authorized_keys"
chown --recursive ${GITHUB_RUNNER_USER}:${GITHUB_RUNNER_USER} /home/${GITHUB_RUNNER_USER}/.ssh

echo "Setting up python3"
brew install python3
curl -sS https://bootstrap.pypa.io/get-pip.py | python3

echo "Setting up docker"
brew install docker

usermod -aG docker ${GITHUB_RUNNER_USER}
chmod 666 /var/run/docker.sock
