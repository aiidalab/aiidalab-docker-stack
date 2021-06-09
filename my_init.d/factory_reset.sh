#!/bin/bash -e

# Debugging.
set -x

# Environment.
export SHELL=/bin/bash

# Performing the factory reset of your AiiDAlab environment:
# 0 - do nothing
# 1 - remove aiidalab apps and things installed in the .local folder
# 2 - remove the entire content of the home folder.

if [[ "${AIIDALAB_FACTORY_RESET}" == 0 ]]; then
  exit 0
fi

if [[ "${AIIDALAB_FACTORY_RESET}" == 1 ]]; then
  rm -r /home/${SYSTEM_USER}/apps
  rm -r /home/${SYSTEM_USER}/.local

elif [[ "${AIIDALAB_FACTORY_RESET}" == 2 ]]; then
  rm -r /home/${SYSTEM_USER}/*

fi


