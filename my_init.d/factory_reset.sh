#!/bin/bash -eu

# Environment.
export SHELL=/bin/bash

# Bit mask for performing factory reset of the AiiDAlab environment:
# 0b000 0 - No reset (noop).
# 0b001 1 - Remove locally installed software and apps (removes ~/apps/ and ~/.local/).
# 0b010 2 - Remove all files and directories within the users home directory.

# If the ~/AIIDALAB_FACTORY_RESET file exists, parse it (and remove it).
if [ -e "/home/${SYSTEM_USER}/AIIDALAB_FACTORY_RESET" ]; then
  RESET_MODE="`cat /home/${SYSTEM_USER}/AIIDALAB_FACTORY_RESET`"
  rm -f "/home/${SYSTEM_USER}/AIIDALAB_FACTORY_RESET"  # Remove file after parsing.
fi

# If the AIIDALAB_FACTORY_RESET environment variable is set, it takes preference (default mode=0):
RESET_MODE="${AIIDALAB_FACTORY_RESET:-${RESET_MODE:-0}}"

# Warn about unknown mode.
if (( ${RESET_MODE} > 0x3 )); then
  echo "factory reset: WARNING: UNKNOWN RESET MODE (${RESET_MODE}) CONTAINS UNKNOWN BITS."
fi

# Perform the individual reset functions:

# mode==0 -> noop
if (( ${RESET_MODE} == 0)); then  # noop
    echo "factory reset: No reset (mode=0)."
fi

# mode & 001 -> delete ~/apps/ and ~/.local/
if (( (${RESET_MODE} & 0x1) == 0x1)); then
  echo "factory reset: Remove apps (~/apps/) and local software installation (~/.local/)."
  rm -rf "/home/${SYSTEM_USER}/apps"
  rm -rf "/home/${SYSTEM_USER}/.local"
fi

# mode & 010 -> delete all home directory contents
if (( (${RESET_MODE} & 0x2) == 0x2)); then
  echo "factory reset: Remove user home directory contents."
  find "/home/${SYSTEM_USER}/" -mindepth 1 -delete
fi
