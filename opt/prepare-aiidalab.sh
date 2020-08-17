#!/bin/bash -e

# Debugging.
set -x

# Environment.
export SHELL=/bin/bash

# Setup pseudopotentials.
if [ ! -e /home/${SYSTEM_USER}/SKIP_IMPORT_PSEUDOS ]; then
   verdi data upf listfamilies | grep 'SSSP_1.1_efficiency'|| verdi import -n /opt/pseudos/SSSP_efficiency_pseudos.aiida
   verdi data upf listfamilies | grep 'SSSP_1.1_precision' || verdi import -n /opt/pseudos/SSSP_precision_pseudos.aiida
fi

# Setup AiiDA jupyter extension.
# Don't forget to copy this file to .ipython/profile_default/startup/
# aiida/tools/ipython/aiida_magic_register.py
if [ ! -e /home/${SYSTEM_USER}/.ipython/profile_default/startup/aiida_magic_register.py ]; then
   mkdir -p /home/${SYSTEM_USER}/.ipython/profile_default/startup/
   cat << EOF > /home/${SYSTEM_USER}/.ipython/profile_default/startup/aiida_magic_register.py
if __name__ == "__main__":

    try:
        import aiida
        del aiida
    except ImportError:
        pass
    else:
        import IPython
        # pylint: disable=ungrouped-imports
        from aiida.tools.ipython.ipython_magics import load_ipython_extension

        # Get the current Ipython session
        IPYSESSION = IPython.get_ipython()

        # Register the line magic
        load_ipython_extension(IPYSESSION)
EOF
fi

# Create apps folder and make its subfolders importable from Python.
if [ ! -e /home/${SYSTEM_USER}/apps ]; then
  # Create apps folder and make it importable from python.
  mkdir -p /home/${SYSTEM_USER}/apps
  touch /home/${SYSTEM_USER}/apps/__init__.py
  INITIAL_SETUP=true
fi

# Install the home app.
if [ ! -e /home/${SYSTEM_USER}/apps/home ]; then
    echo "Install home app."
    ln -s /opt/aiidalab-home /home/${SYSTEM_USER}/apps/home
elif [[ -d /home/${SYSTEM_USER}/apps/home && ! -L /home/${SYSTEM_USER}/apps/home ]]; then
  mv /home/${SYSTEM_USER}/apps/home /home/${SYSTEM_USER}/apps/.home-`date --iso-8601=seconds`
  ln -s /opt/aiidalab-home /home/${SYSTEM_USER}/apps/home
fi

# Install/upgrade apps.
if [[ ${INITIAL_SETUP} == true ||  "${AIIDALAB_SETUP}" == "true" ]]; then
  # Base widgets app.
  if [ ! -e /home/${SYSTEM_USER}/apps/aiidalab-widgets-base ]; then
    git clone https://github.com/aiidalab/aiidalab-widgets-base /home/${SYSTEM_USER}/apps/aiidalab-widgets-base
    cd /home/${SYSTEM_USER}/apps/aiidalab-widgets-base
    git checkout ${AIIDALAB_DEFAULT_GIT_BRANCH}
    cd -
  fi 
  # Quantum Espresso app.
  if [ ! -e /home/${SYSTEM_USER}/apps/quantum-espresso ]; then
    git clone https://github.com/aiidalab/aiidalab-qe.git /home/${SYSTEM_USER}/apps/quantum-espresso
    cd /home/${SYSTEM_USER}/apps/quantum-espresso
    git checkout ${AIIDALAB_DEFAULT_GIT_BRANCH}
    cd -
  fi
fi

