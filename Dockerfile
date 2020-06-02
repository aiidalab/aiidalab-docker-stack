FROM aiidateam/aiida-core:latest

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV AIIDALAB_DEFAULT_GIT_BRANCH master

USER root

# Install OS dependencies.
RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    cp2k                  \
    file                  \
    libssl-dev            \
    libffi-dev            \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
    quantum-espresso      \
  && rm -rf /var/lib/apt/lists/*

# Install what is needed for Jupyter Lab.
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*

# Quantum-Espresso Pseudo Potentials.
# TODO, remove when https://github.com/aiidateam/aiida-sssp/pull/25 is merged
# and installed on AiiDA lab
WORKDIR /opt/pseudos
RUN base_url=http://legacy-archive.materialscloud.org/file/2018.0001/v3;  \
wget ${base_url}/SSSP_efficiency_pseudos.aiida;                           \
wget ${base_url}/SSSP_precision_pseudos.aiida;                            \
chown -R root:root /opt/pseudos/;                                         \
chmod -R +r /opt/pseudos/

# Install Python packages needed for AiiDA lab.
RUN pip install 'aiidalab==v20.05.0b1'

# Installing Jupyter-related things in the root environment.
RUN /usr/bin/pip3 install          \
    'jupyterhub==1.1.0'            \
    'jupyterlab==2.1.4'            \
    'fileupload==0.1.5'            \
    'nbserverproxy==0.8.8'         \
    'appmode==0.7.0'               \
    'notebook==6.0.3'              \
    'nglview==2.7.5'               \
    'voila==0.1.21'

RUN python -m ipykernel install

# Enable extensions.
# NOTE: for this to work I had to install nglview and appmode-aiidalab to the
# /usr/bin/pip3 python environment
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix nbserverproxy
RUN /usr/local/bin/jupyter nbextension     enable --py --sys-prefix appmode
RUN /usr/local/bin/jupyter serverextension enable --py --sys-prefix appmode
RUN /usr/local/bin/jupyter nbextension enable nglview --py --sys-prefix
# TODO: delete, when https://github.com/aiidalab/aiidalab-widgets-base/issues/31 is fixed
# the fileupload extension also needs to be "installed".
RUN /usr/local/bin/jupyter nbextension install --py --sys-prefix fileupload

# Install jupyterlab theme.
# Takes about 4 minutes and 10 seconds.
#WORKDIR /opt/jupyterlab-theme
#RUN git clone https://github.com/aiidalab/jupyterlab-theme && \
#    cd jupyterlab-theme && \
#     npm install && \
#     npm run build && \
#     npm run build:webpack && \
#     npm pack ./ && \ 
#     /usr/local/bin/jupyter labextension install *.tgz && \
#    cd ..

# Populate reentry cache for root user https://pypi.python.org/pypi/reentry/.
RUN reentry scan

# Install some useful packages that are not available on PyPi
RUN conda install --yes -c conda-forge rdkit
RUN conda install --yes -c openbabel openbabel
RUN conda install --yes -c conda-forge dscribe "tornado<5"

# Expose port 8888.
EXPOSE 8888

# Prepare user's folders for AiiDA lab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run


# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
