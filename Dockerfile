FROM aiidateam/aiida-core:latest

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps

USER root

# Install OS dependencies.
RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    cp2k                  \
    file                  \
    libssl-dev            \
    libffi-dev            \
    quantum-espresso      \
  && rm -rf /var/lib/apt/lists/*

# Install what is needed for Jupyter Lab.
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*

# Quantum-Espresso Pseudo Potentials.
WORKDIR /opt/pseudos
RUN base_url=http://archive.materialscloud.org/file/2018.0001/v3;  \
wget ${base_url}/SSSP_efficiency_pseudos.aiida;                    \
wget ${base_url}/SSSP_precision_pseudos.aiida;                     \
chown -R root:root /opt/pseudos/;                                  \
chmod -R +r /opt/pseudos/

# Install Python packages needed for AiiDA lab.
RUN pip install                    \
    'aiidalab==v20.02.a1'          \
    'jupyterhub==0.9.4'            \
    'jupyterlab==0.35.4'           \
    'nbserverproxy==0.8.8'

# Enable nbserverproxy extension.
RUN jupyter serverextension enable --sys-prefix --py nbserverproxy

# Enables better integration with Jupyter Hub.
# https://jupyterlab.readthedocs.io/en/stable/user/jupyterhub.html#further-integration
# Takes about 3 minutes and 20 seconds.
RUN jupyter labextension install @jupyterlab/hub-extension

# TODO: delete, when https://github.com/aiidalab/aiidalab-widgets-base/issues/31 is fixed
# the fileupload extension also needs to be "installed".
RUN jupyter nbextension install --sys-prefix --py fileupload

# Install jupyterlab theme.
# Takes about 4 minutes and 10 seconds.
WORKDIR /opt/jupyterlab-theme
RUN git clone https://github.com/aiidalab/jupyterlab-theme && \
    cd jupyterlab-theme && \
     npm install && \
     npm run build && \
     npm run build:webpack && \
     npm pack ./ && \ 
     jupyter labextension install *.tgz && \
    cd ..

# Populate reentry cache for root user https://pypi.python.org/pypi/reentry/.
RUN reentry scan

# Prepare user's folders for AiiDA lab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run

# Install some useful packages that are not available on PyPi
RUN conda install --yes -c conda-forge rdkit
RUN conda install --yes -c openbabel openbabel
RUN conda install --yes -c conda-forge dscribe

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
