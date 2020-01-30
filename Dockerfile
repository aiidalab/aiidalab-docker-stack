FROM aiidateam/aiida-core:latest

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"


# Note: The following config can be changed at build time:
#   docker build  --build-arg NB_UID=200
ARG NB_USER="scientist"
ARG NB_UID="1000"
ARG NB_GID="1000"

ENV AIIDALAB_HOME /home/${SYSTEM_USER}
ENV AIIDALAB_APPS ${AIIDALAB_HOME}/apps

USER root

RUN apt-get update && apt-get install -y  \
    ca-certificates       \
    cp2k                  \
    file                  \
    libssl-dev            \
    libffi-dev            \
    quantum-espresso      \
  && rm -rf /var/lib/apt/lists/*

# needed for jupyterlab
RUN apt-get update && apt-get install -y \
     nodejs                \
     npm                   \
  && rm -rf /var/lib/apt/lists/*


# Quantum-Espresso Pseudo Potentials
WORKDIR /opt/pseudos
RUN base_url=http://archive.materialscloud.org/file/2018.0001/v2;  \
    for name in SSSP_efficiency_pseudos SSSP_precision_pseudos; do \
       wget ${base_url}/${name}.tar.gz;                            \
       tar -zxvf ${name}.tar.gz;                                   \
    done;                                                          \
    chown -R root:root /opt/pseudos/;                              \
    chmod -R +r /opt/pseudos/

# install packages that are not in the aiidalab meta package
# 'fastentrypoints' is to fix problems with aiida-quantumespresso plugin installation
RUN pip3 install --upgrade         \
    'fastentrypoints'              \
    'tornado==5.1.1'               \
    'jupyterhub==0.9.4'            \
    'notebook==5.7.4'              \
    'nbserverproxy==0.8.8'         \
    'jupyterlab==0.35.4'           \
    'appmode-aiidalab==0.5.0.1'

# enable nbserverproxy extension
RUN jupyter serverextension enable --sys-prefix --py nbserverproxy

# This already enables jupyter notebook and server extensions
RUN pip3 install aiidalab==v19.11.0a2

# activate ipython kernel
RUN python3 -m ipykernel install

# TODO: delete, when https://github.com/aiidalab/aiidalab-widgets-base/issues/31 is fixed
# the fileupload extension also needs to be "installed"
RUN jupyter nbextension install --sys-prefix --py fileupload

# Enable nbserverproxy extension.
RUN jupyter serverextension enable --sys-prefix --py nbserverproxy
# Enables better integration with jupyterhub.
# https://jupyterlab.readthedocs.io/en/stable/user/jupyterhub.html#further-integration
RUN jupyter labextension install @jupyterlab/hub-extension

# Install jupyterlab theme.
WORKDIR /opt/jupyterlab-theme
RUN git clone https://github.com/aiidalab/jupyterlab-theme && \
    cd jupyterlab-theme && \
     npm install && \
     npm run build && \
     npm run build:webpack && \
     npm pack ./ && \ 
     jupyter labextension install *.tgz && \
    cd ..

# install MolPad
WORKDIR /opt
RUN git clone https://github.com/oschuett/molview-ipywidget.git  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python2.7/dist-packages/molview_ipywidget  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python3.6/dist-packages/molview_ipywidget  && \
    jupyter nbextension     install --sys-prefix --py --symlink molview_ipywidget  && \
    jupyter nbextension     enable  --sys-prefix --py           molview_ipywidget

# populate reentry cache for root user https://pypi.python.org/pypi/reentry/
RUN reentry scan

# Prepare user's folders for AiiDA lab launch.
COPY opt/aiidalab-singleuser /opt/
COPY opt/prepare-aiidalab.sh /opt/
COPY my_init.d/prepare-aiidalab.sh /etc/my_init.d/80_prepare-aiidalab.sh

# Start Jupyter notebook
COPY opt/start-notebook.sh /opt/
COPY my_init.d/start-notebook.sh /etc/my_init.d/XX_start-notebook.sh

# Expose port 8888.
EXPOSE 8888

# Remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]
