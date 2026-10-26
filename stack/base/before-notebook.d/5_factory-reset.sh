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

  # No reset requested, nothing to do. Return 0 explicitly: a bare `return`
  # would pass on the failed test's status and, as this hook is sourced by
  # a `set -e` script, abort container startup.
  [ -e "${reset_file}" ] || return 0

  # Only accept a regular file: a directory would make the read fail (aborting
  # startup), a FIFO would block it, and a symlink could point anywhere.
  if [ ! -f "${reset_file}" ] || [ -L "${reset_file}" ]; then
    echo "factory reset: WARNING: ${reset_file} is not a regular file, no reset performed."
    return 0
  fi

  # Bounded read; a read failure must not abort container startup.
  reset_mode="$(head -c 64 "${reset_file}" | tr -d '[:space:]')" || true
  rm -f "${reset_file}"  # Remove file after parsing.

  case "${reset_mode}" in
    local)
      if [ -e "/home/${NB_USER}/.local" ]; then
        local_backup="/home/${NB_USER}/.local~`date --iso-8601=seconds`"
        echo "factory reset: Move ~/.local/ to ${local_backup}."
        mv --no-target-directory "/home/${NB_USER}/.local" "${local_backup}"
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
