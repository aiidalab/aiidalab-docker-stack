#!/bin/bash -e

# Debugging.
set -x

# Install qeapp.
aiidalab install --yes quantum-espresso==${AIIDALAB_QE_VERSION}

# Force restart daemon to make sure that the new version is used.
verdi daemon restart --reset --timeout 30
