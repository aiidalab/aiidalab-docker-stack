#!/bin/bash
set -ex

GITHUB_RUNNER_USER="runner-user"

if  [ $UID -ne 0 ] ; then echo "Please run $0 as root." && exit 1; fi

getHiddenUserUid()
{
    local __UIDS=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ugr)

    #echo $__UIDS
    local __NewUID
    for __NewUID in $__UIDS
    do
        if [[ $__NewUID -lt 499 ]] ; then
            break;
        fi
    done

    echo $((__NewUID+1))
}

getInteractiveUserUid()
{
    # Find out the next available user ID
    local __MAXID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -ug | tail -1)
    echo $((__MAXID+1))
}


echo "Setting up runner-user, who will run GitHub Actions runner"

# Create the user account by running dscl (normally you would have to do each of these commands one
# by one in an obnoxious and time consuming way.

FULLNAME="Runner User"
USERID=$(getInteractiveUserUid)
GROUPID=20

read -s -p "Enter a password for this user: " PASSWORD
echo
read -s -p "Validate a password: " PASSWORD_VALIDATE
echo

if [[ $PASSWORD != $PASSWORD_VALIDATE ]] ; then
    echo "Passwords do not match!"
    exit 1;
fi

sysadminctl -addUser ${GITHUB_RUNNER_USER} -fullName "${FULLNAME}" -UID ${USERID} -GID ${GROUPID} -password "${PASSWORD}" -home /Users/${GITHUB_RUNNER_USER} -admin

mkdir -p /Users/${GITHUB_RUNNER_USER}/.ssh/
cp "/Users/${SUDO_USER}/.ssh/authorized_keys" "/Users/${GITHUB_RUNNER_USER}/.ssh/authorized_keys" || true
chown -R $USERID:$GROUPID /Users/${GITHUB_RUNNER_USER}/.ssh

# Install homebrew (as runner-user)
# You may need to run this by hand, but only the first time setup the self-hosted runner it is required.
echo "Setting up homebrew"
sudo -i -u ${GITHUB_RUNNER_USER} bash << EOF
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh
echo "Setting up python3"
brew install python
# For Apple Silicon machines, the path are slightly different.
# After running brew install python, must ensure your ~/.zprofile uses the correct Homebrew paths:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/${GITHUB_RUNNER_USER}/.zprofile
echo 'export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"' >> /Users/${GITHUB_RUNNER_USER}/.zprofile
echo 'export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"' >> /Users/${GITHUB_RUNNER_USER}/.zprofile
echo "Setting up docker "
brew install docker
brew install docker-compose
brew install docker-buildx
brew install colima
brew install jq
EOF
