#!/bin/bash -e

# Debugging.
set -x

# Install qeapp if it is not already installed.
if aiidalab list | grep -q quantum-espresso; then
    echo "Quantum ESPRESSO app is already installed."
    exit 0
else
    echo "Installing Quantum ESPRESSO app."
    aiidalab install --yes quantum-espresso==${AIIDALAB_QE_VERSION}
fi

# Force restart daemon to make sure that the new version is used.
verdi daemon restart --reset --timeout 30
