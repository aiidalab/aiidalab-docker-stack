#!/bin/bash -e

# Debugging.
set -x

# Install qeapp if it is not already installed.
if aiidalab list | grep -q quantum-espresso; then
    echo "Quantum ESPRESSO app is already installed."
else
    echo "Installing Quantum ESPRESSO app."
    aiidalab install --yes quantum-espresso==${AIIDALAB_QE_VERSION}
fi
