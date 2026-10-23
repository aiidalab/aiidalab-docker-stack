#!/bin/bash

# Factory reset of the AiiDAlab environment, requested by writing the reset
# mode into the ~/AIIDALAB_FACTORY_RESET file (the file is removed after parsing).
# Supported modes:
#   local - Reset local software installation (moves ~/.local/ to ~/.local~<date>).
#
# This hook is sourced by the container start script, so the logic is wrapped in
# a function to keep its variables out of the environment of subsequent hooks.

factory_reset() {
  local reset_file="/home/${NB_USER}/AIIDALAB_FACTORY_RESET"
  local reset_mode local_backup

  if [ ! -e "${reset_file}" ]; then
    echo "factory reset: No reset requested."
    return 0
  fi

  reset_mode="$(tr -d '[:space:]' < "${reset_file}")"
  rm -f "${reset_file}"  # Remove file after parsing.

  case "${reset_mode}" in
    local)
      if [ -e "/home/${NB_USER}/.local" ]; then
        local_backup="/home/${NB_USER}/.local~`date --iso-8601=seconds`"
        echo "factory reset: Move ~/.local/ to ${local_backup}."
        mv "/home/${NB_USER}/.local" "${local_backup}" \
          || echo "factory reset: WARNING: Failed to move ~/.local/, no reset performed."
      else
        echo "factory reset: No ~/.local/ to reset."
      fi
      ;;
    *)
      echo "factory reset: WARNING: Unknown reset mode (${reset_mode}), no reset performed."
      ;;
  esac
}

factory_reset
unset -f factory_reset
