#!/bin/bash -eu

# Environment.
export SHELL=/bin/bash

# Factory reset of the AiiDAlab environment, requested by writing the reset
# mode into the ~/AIIDALAB_FACTORY_RESET file (the file is removed after parsing).
# Supported modes:
#   local - Reset local software installation (moves ~/.local/ to ~/.local~<date>).

RESET_FILE="/home/${NB_USER}/AIIDALAB_FACTORY_RESET"

if [ -e "${RESET_FILE}" ]; then
  RESET_MODE="$(tr -d '[:space:]' < "${RESET_FILE}")"
  rm -f "${RESET_FILE}"  # Remove file after parsing.

  case "${RESET_MODE}" in
    local)
      if [ -e "/home/${NB_USER}/.local" ]; then
        LOCAL_BACKUP="/home/${NB_USER}/.local~`date --iso-8601=seconds`"
        echo "factory reset: Move ~/.local/ to ${LOCAL_BACKUP}."
        mv "/home/${NB_USER}/.local" "${LOCAL_BACKUP}" \
          || echo "factory reset: WARNING: Failed to move ~/.local/, no reset performed."
      else
        echo "factory reset: No ~/.local/ to reset."
      fi
      ;;
    *)
      echo "factory reset: WARNING: Unknown reset mode (${RESET_MODE}), no reset performed."
      ;;
  esac
else
  echo "factory reset: No reset requested."
fi
