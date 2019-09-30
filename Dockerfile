# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# Based on Ubuntu 18.04 since v0.11
FROM phusion/baseimage:0.11

LABEL maintainer="Materials Cloud Team <aiidalab@materialscloud.org>"


# Note: The following config can be changed at build time:
#   docker build  --build-arg NB_UID=200
ARG NB_USER="scientist"
ARG NB_UID="1000"
ARG NB_GID="1000"


USER root

# Add switch mirror to fix issue #9
# https://github.com/aiidalab/aiidalab-docker-stack/issues/9
RUN echo "deb http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \ndeb-src http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \n" >> /etc/apt/sources.list

# install debian packages
# Note: prefix all 'apt-get install' lines with 'apt-get update' to prevent failures in partial rebuilds
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata

RUN apt-get update && apt-get install -y --no-install-recommends  \
    bzip2                 \
    build-essential       \
    ca-certificates       \
    cp2k                  \
    file                  \
    git                   \
    gir1.2-gtk-3.0        \
    gnupg                 \
    graphviz              \
    locales               \
    less                  \
    libssl-dev            \
    libffi-dev            \
    postgresql            \
    psmisc                \
    python-dev            \
    python-pip            \
    python-setuptools     \
    python-wheel          \
    python3-dev           \
    python3-gi            \
    python3-gi-cairo      \
    python3-pip           \
    python3-psycopg2      \
    python3-setuptools    \
    python3-tk            \
    python3-wheel         \
    python-tk             \
    quantum-espresso      \
    rabbitmq-server       \
    rsync                 \
    ssh                   \
    unzip                 \
    vim                   \
    wget                  \
    zip                   \
  && rm -rf /var/lib/apt/lists/*

# needed for jupyterlab
RUN apt-get update && apt-get install -y \
    nodejs                \
    npm                   \
  && rm -rf /var/lib/apt/lists/*

# fix locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Quantum-Espresso Pseudo Potentials
WORKDIR /opt/pseudos
RUN base_url=http://archive.materialscloud.org/file/2018.0001/v2;  \
    for name in SSSP_efficiency_pseudos SSSP_precision_pseudos; do \
       wget ${base_url}/${name}.tar.gz;                            \
       tar -zxvf ${name}.tar.gz;                                   \
    done;                                                          \
    chown -R root:root /opt/pseudos/;                              \
    chmod -R +r /opt/pseudos/


# keep Python2 kernel for the back-compatibility only
RUN pip2 install ipykernel

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

# workaround to fix pymatgen installation
RUN pip install numpy==1.15.4

# This already enables jupyter notebook and server extensions
RUN pip3 install aiidalab==v19.11.0a2

# activate ipython kernels
RUN python2 -m ipykernel install
RUN python3 -m ipykernel install

# Set Python3 be the default python version
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# the fileupload extension also needs to be "installed"
RUN jupyter nbextension install --sys-prefix --py fileupload

# enable nbserverproxy extension
RUN jupyter serverextension enable --sys-prefix --py nbserverproxy
# enables better integration with jupyterhub
# https://jupyterlab.readthedocs.io/en/stable/user/jupyterhub.html#further-integration
RUN jupyter labextension install @jupyterlab/hub-extension


# Install jupyterlab theme
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

#===============================================================================
ADD fix-permissions /usr/local/bin/fix-permissions
RUN mkdir /project                                                 && \
    useradd --home /project --uid $NB_UID --shell /bin/bash $NB_USER
RUN fix-permissions /project

# launch postgres server
COPY opt/postgres.sh /opt/
COPY my_init.d/start-postgres.sh /etc/my_init.d/20_start-postgres.sh

# launch start-singleuser
COPY opt/start-singleuser.sh /opt/
COPY my_init.d/start-singleuser.sh /etc/my_init.d/30_start-singleuser.sh

# launch rabbitmq server
RUN mkdir /etc/service/rabbitmq
COPY service/rabbitmq /etc/service/rabbitmq/run

# launch jupyterhub-singleuser
COPY opt/aiidalab-jupyterhub-singleuser /opt/
COPY opt/start-jupytehub-singleuser.sh /opt/
COPY service/jupyterhub-singleuser /etc/service/jupyterhub-singleuser/run

# launch aiida
RUN mkdir /etc/service/aiida
COPY service/aiida /etc/service/aiida/run

EXPOSE 8888

# remove when the following issue is fixed: https://github.com/jupyterhub/dockerspawner/issues/319
COPY my_my_init /sbin/my_my_init

CMD ["/sbin/my_my_init"]

#EOF
