FROM aiidateam/aiida-core:latest

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"

# Configure environment.
ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

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

ENV MINICONDA_VERSION=4.7.12.1 \
    MINICONDA_MD5=81c773ff87af5cfac79ab862942ab6b3 \
    CONDA_VERSION=4.7.12

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda install --quiet --yes conda && \
    conda install --quiet --yes pip && \
    conda update --all --quiet --yes && \
    conda clean --all -f -y

# Install Python packages needed for AiiDA lab.
RUN pip3 install --upgrade         \
    'jupyterhub==0.9.4'            \
    'jupyterlab==0.35.4'           \
    'nbserverproxy==0.8.8'

# AiiDA lab package goes last, because it overrides tornado.
RUN pip3 install --upgrade 'aiidalab==v19.11.0a2'

# Activate ipython kernel.
# RUN python3 -m ipykernel install

# Enable nbserverproxy extension.
RUN jupyter serverextension enable --sys-prefix --py nbserverproxy

# Enables better integration with Jupyter Hub.
# https://jupyterlab.readthedocs.io/en/stable/user/jupyterhub.html#further-integration
# Quite a slow part.
RUN jupyter labextension install @jupyterlab/hub-extension

# TODO: delete, when https://github.com/aiidalab/aiidalab-widgets-base/issues/31 is fixed
# the fileupload extension also needs to be "installed".
RUN jupyter nbextension install --sys-prefix --py fileupload

# Install jupyterlab theme.
# Also quite slow.
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

# Prepare conda.
COPY my_init.d/prepare-conda.sh /etc/my_init.d/70_prepare-conda.sh

# Prepare user's folders for AiiDA lab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Start Jupyter notebook.
COPY opt/start-notebook.sh /opt/
COPY service/jupyter-notebook /etc/service/jupyter-notebook/run

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319.
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
