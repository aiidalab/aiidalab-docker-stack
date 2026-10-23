#!/bin/bash -eu

# Environment.
export SHELL=/bin/bash

# Factory reset of the AiiDAlab environment, requested by writing the reset
# mode into the ~/AIIDALAB_FACTORY_RESET file (the file is removed after parsing).
# Supported modes:
#   local - Reset local software installation (moves ~/.local/ to ~/.local_backup).

RESET_FILE="/home/${NB_USER}/AIIDALAB_FACTORY_RESET"

if [ -e "${RESET_FILE}" ]; then
  RESET_MODE="$(tr -d '[:space:]' < "${RESET_FILE}")"
  rm -f "${RESET_FILE}"  # Remove file after parsing.

  case "${RESET_MODE}" in
    local)
      echo "factory reset: Move local software installation (~/.local/) to ~/.local_backup."
      mv "/home/${NB_USER}/.local" "/home/${NB_USER}/.local_backup"
      ;;
    *)
      echo "factory reset: WARNING: Unknown reset mode (${RESET_MODE}), no reset performed."
      ;;
  esac
else
  echo "factory reset: No reset requested."
fi
