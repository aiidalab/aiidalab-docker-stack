#!/bin/bash -e

# Debugging.
set -x

# Environment.
export SHELL=/bin/bash

# Fix https://github.com/aiidalab/aiidalab-docker-stack/issues/225
if [ -L /home/${SYSTEM_USER}/${SYSTEM_USER} ]; then
  rm /home/${SYSTEM_USER}/${SYSTEM_USER}
fi

# Setup AiiDA jupyter extension.
# Don't forget to copy this file to .ipython/profile_default/startup/
# aiida/tools/ipython/aiida_magic_register.py
if [ ! -e /home/${SYSTEM_USER}/.ipython/profile_default/startup/aiida_magic_register.py ]; then
   mkdir -p /home/${SYSTEM_USER}/.ipython/profile_default/startup/
   cat << EOF > /home/${SYSTEM_USER}/.ipython/profile_default/startup/aiida_magic_register.py
if __name__ == "__main__":

    try:
        import aiida
        del aiida
    except ImportError:
        pass
    else:
        import IPython
        # pylint: disable=ungrouped-imports
        from aiida.tools.ipython.ipython_magics import load_ipython_extension

        # Get the current Ipython session
        IPYSESSION = IPython.get_ipython()

        # Register the line magic
        load_ipython_extension(IPYSESSION)
EOF
fi

# Create apps folder and make its subfolders importable from Python.
if [ ! -e /home/${SYSTEM_USER}/apps ]; then
  # Create apps folder and make it importable from python.
  mkdir -p /home/${SYSTEM_USER}/apps
  INITIAL_SETUP=1
fi

# Install the home app.
if [ ! -e /home/${SYSTEM_USER}/apps/home ]; then
    echo "Install home app."
    # The home app is installed in system space and linked to from user space.
    # That ensures that users are not inadvertently running the wrong version of
    # the home app for a given system environment, but still makes it possible to
    # manually install a specific version of the home app in between upgrades, e.g.,
    # for development work, by simply replacing the link with a clone of the repository.
    ln -s /opt/aiidalab-home /home/${SYSTEM_USER}/apps/home
elif [[ -d /home/${SYSTEM_USER}/apps/home && ! -L /home/${SYSTEM_USER}/apps/home ]]; then
  # Backup an existing repository of the home app and replace with link to /opt/aiidalab-home.
  # This mechanism preserves potential development work on a manually installed repository
  # of the home app and also constitutes a migration path for existing aiidalab accounts, where
  # the home app was installed directly into user space by default.
  mv /home/${SYSTEM_USER}/apps/home /home/${SYSTEM_USER}/apps/.home~`date --iso-8601=seconds` \
    && ln -s /opt/aiidalab-home /home/${SYSTEM_USER}/apps/home || echo "WARNING: Unable to install home app."
fi


# Install default apps (see the Dockerfile for an explanation of the
# AIIDALAB_DEFAULT_APPS variable).
if [[ ${INITIAL_SETUP} == 1 ]]; then

  # Iterate over lines in AIIDALAB_DEFAULT_APPS variable.
  for app in ${AIIDALAB_DEFAULT_APPS:-}; do
      aiidalab install --yes "${app}"
  done
fi

# Clear user trash directory.
if [ -e /home/${SYSTEM_USER}/.trash ]; then
  rm -rf /home/${SYSTEM_USER}/.trash/*
fi

# Remove old apps_meta.sqlite requests cache files.
find -L /home/${SYSTEM_USER} -maxdepth 3 -name apps_meta.sqlite -writable -delete

# Remove old temporary notebook files.
find -L /home/${SYSTEM_USER}/apps -maxdepth 2 -type f -name .*.ipynb -writable -delete

# Uninstall aiidalab from user packages (if present).
# Would otherwise interfere with the system package.
USER_AIIDALAB_PACKAGE="$(/opt/conda/bin/python -c 'import site; print(site.USER_SITE)')/aiidalab"
if [ -e ${USER_AIIDALAB_PACKAGE} ]; then
  echo "Uninstall local installation of aiidalab package."
  /opt/conda/bin/python -m pip uninstall --yes aiidalab
fi
