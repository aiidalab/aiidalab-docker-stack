#!/bin/bash -e

# Debugging.
set -x

# Environment.
export SHELL=/bin/bash

# Performing factory reset of your AiiDAlab environment:
# 0 - No reset (noop).
# 1 - Remove locally installed software and apps (removes ~/apps/ and ~/.local/).
# 2 - Remove all files and directories within the users home directory.


case "${AIIDALAB_FACTORY_RESET}" in

  0)
    exit 0
    ;;

  1)
    rm -rf "/home/${SYSTEM_USER}/apps"
    rm -rf "/home/${SYSTEM_USER}/.local"
    ;;

  2)
    find home/${SYSTEM_USER}/ -mindepth 1 -delete
    ;;

  *)
    echo "Unknown factory reset mode: ${AIIDALAB_FACTORY_RESET}"
    exit 1
    ;;
esac
