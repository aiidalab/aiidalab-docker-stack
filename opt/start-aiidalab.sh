#!/bin/bash -e

# Debugging.
set -x

# Environment.
export SHELL=/bin/bash

# Setup CP2K code.
code_name=cp2k
verdi code show ${code_name}@${computer_name} || verdi code setup \
    --non-interactive                                             \
    --label ${code_name}                                          \
    --description "cp2k on this computer"                         \
    --input-plugin cp2k                                           \
    --computer localhost                                          \
    --remote-abs-path `which cp2k.popt`

# Setup Quantum ESPRESSO pw.x code.
code_name=pw
verdi code show ${code_name}@${computer_name} || verdi code setup \
    --non-interactive                                             \
    --label ${code_name}                                          \
    --description "pw.x on this computer"                         \
    --input-plugin quantumespresso.pw                             \
    --computer localhost                                          \
    --remote-abs-path `which pw.x`

# Setup pseudopotentials.
if [ ! -e /home/$SYSTEM_USER/SKIP_IMPORT_PSEUDOS ]; then
      cd /opt/pseudos
      verdi data upf listfamilies | grep 'SSSP_efficiency_v1.0'|| verdi data upf uploadfamily SSSP_efficiency_pseudos 'SSSP_efficiency_v1.0' 'SSSP pseudopotential library'
      verdi data upf listfamilies | grep 'SSSP_precision_v1.0' || verdi data upf uploadfamily SSSP_precision_pseudos 'SSSP_precision_v1.0' 'SSSP pseudopotential library'
fi

# Setup AiiDA jupyter extension.
# Don't forget to copy this file to .ipython/profile_default/startup/
# aiida/tools/ipython/aiida_magic_register.py
if [ ! -e /home/$SYSTEM_USER/.ipython/profile_default/startup/aiida_magic_register.py ]; then
   mkdir -p /home/$SYSTEM_USER/.ipython/profile_default/startup/
   cat << EOF > /home/$SYSTEM_USER/.ipython/profile_default/startup/aiida_magic_register.py
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

# Install/upgrade apps.
if [ ! -e /home/$SYSTEM_USER/apps ]; then
   mkdir /home/$SYSTEM_USER/apps
   touch /home/$SYSTEM_USER/apps/__init__.py
   git clone https://github.com/aiidalab/aiidalab-home /home/$SYSTEM_USER/apps/home
   cd /home/$SYSTEM_USER/apps/home
   git checkout aiida_v1.0
   cd -
   echo '{
  "hidden": [],
  "order": [
    "aiida-tutorials",
    "cscs",
    "calcexamples"
  ]
}' > /home/$SYSTEM_USER/apps/home/.launcher.json
   git clone https://github.com/aiidalab/aiidalab-widgets-base /home/$SYSTEM_USER/apps/aiidalab-widgets-base
   cd /home/$SYSTEM_USER/apps/aiidalab-widgets-base
   git checkout aiida-1.0
   cd -
   git clone https://github.com/aiidalab/aiidalab-calculation-examples.git /home/$SYSTEM_USER/apps/calcexamples
   cd /home/$SYSTEM_USER/apps/calcexamples
   git checkout aiida-1.0
   cd -
fi


# Enter home folder and start jupyterhub-singleuser.
cd /home/$SYSTEM_USER
/opt/aiidalab-singleuser                                \
    --ip=0.0.0.0                                                   \
    --port=8888                                                    \
    --notebook-dir="/home/$SYSTEM_USER"                            \
    --NotebookApp.iopub_data_rate_limit=1000000000                 \
    --NotebookApp.default_url="/apps/apps/home/start.ipynb"
