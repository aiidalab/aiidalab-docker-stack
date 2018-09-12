# Using ubuntu:latest to get recent versions of CP2K and QE.
#
# see also:
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile
#
# Using latest LTS release, see https://hub.docker.com/_/ubuntu/
FROM ubuntu:latest

USER root

# Add switch mirror to fix issue #9
# https://github.com/materialscloud-org/mc-docker-stack/issues/9
RUN echo "deb http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \ndeb-src http://mirror.switch.ch/ftp/mirror/ubuntu/ bionic main \n" >> /etc/apt/sources.list

# install debian packages
# Note: prefix all 'apt-get install' lines with 'apt-get update' to prevent failures in partial rebuilds
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    tzdata 
RUN apt-get update && apt-get install -y --no-install-recommends  \
    graphviz              \
    locales               \
    less                  \
    psmisc                \
    bzip2                 \
    build-essential       \
    libssl-dev            \
    libffi-dev            \
    python-dev            \
    git                   \
    gnupg                 \
    cp2k                  \
    quantum-espresso      \
    python-pip            \
    python-setuptools     \
    python-wheel          \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
    python-tk             \
    wget                  \
    ca-certificates       \
    vim                   \
    ssh                   \
    file                  \
    zip                   \
    unzip                 \
    rsync                 \
  && rm -rf /var/lib/apt/lists/*

# Add repo for postgres-9.6
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
RUN wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
RUN apt-get update && apt-get install -y --no-install-recommends  \
    postgresql-9.6        \
  && rm -rf /var/lib/apt/lists/*

# fix locales
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8


# Quantum-Espresso Pseudo Potentials
WORKDIR /opt/pseudos
RUN base_url=http://archive.materialscloud.org/file/2018.0001/v1;  \
    for name in SSSP_efficiency_pseudos SSSP_accuracy_pseudos; do  \
       wget ${base_url}/${name}.aiida;                             \
    done;                                                                      \
    chown -R root:root /opt/pseudos/;                                          \
    chmod -R +r /opt/pseudos/

## install rclone
#WORKDIR /opt/rclone
#RUN wget https://downloads.rclone.org/rclone-v1.38-linux-amd64.zip;  \
#    unzip rclone-v1.38-linux-amd64.zip;                              \
#    ln -s rclone-v1.38-linux-amd64/rclone .

# install PyPI packages for Python 3
RUN pip3 install --upgrade         \
    'tornado==5.0.2'               \
    'jupyterhub==0.9.2'            \
    'notebook==5.5.0'              \
    'appmode-aiidalab==0.4.0'

# install PyPI packages for Python 2.
# This already enables jupyter notebook and server extensions
RUN pip2 install --upgrade --process-dependency-links git+https://github.com/materialscloud-org/aiidalab-metapkg@v18.08.0

# the fileupload extension also needs to be "installed"
RUN jupyter nbextension install --sys-prefix --py fileupload

## Get latest bugfixes from aiida-core
RUN pip2 install --no-dependencies git+https://github.com/ltalirz/aiida_core@v0.12.1_expire_on_commit_false
## TODO: Remove this after aiida-core 0.11.2 is released
#WORKDIR /opt/aiida-core
#RUN git clone https://github.com/aiidateam/aiida_core.git && \
#    cd aiida_core && \
#     git checkout release_v0.11.2 && \
#     pip install --no-deps . && \
#    cd ..

# activate ipython kernels
RUN python2 -m ipykernel install
RUN python3 -m ipykernel install

# install MolPad
WORKDIR /opt
RUN git clone https://github.com/oschuett/molview-ipywidget.git  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python2.7/dist-packages/molview_ipywidget  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python3.6/dist-packages/molview_ipywidget  && \
    jupyter nbextension     install --sys-prefix --py --symlink molview_ipywidget  && \
    jupyter nbextension     enable  --sys-prefix --py           molview_ipywidget

# create symlink for legacy workflows
RUN cd /usr/local/lib/python2.7/dist-packages/aiida/workflows; rm -rf user; ln -s /project/workflows user

# populate reentry cache for root user https://pypi.python.org/pypi/reentry/
RUN reentry scan

# disable MPI warnings that confuse ASE
# https://www.mail-archive.com/users@lists.open-mpi.org/msg30611.html
RUN echo "btl_base_warn_component_unused = 0" >> /etc/openmpi/openmpi-mca-params.conf

## install Tini
## TODO: might not be needed in the future, Docker now has an init built-in
#WORKDIR /opt
#RUN wget https://github.com/krallin/tini/releases/download/v0.15.0/tini && \
#    chmod +x /opt/tini
#ENTRYPOINT ["/opt/tini", "--"]

#===============================================================================
RUN mkdir /project                                                 && \
    useradd --home /project --uid 1234 --shell /bin/bash scientist && \
    chown -R scientist:scientist /project

EXPOSE 8888
USER scientist
COPY postgres.sh /opt/

COPY start-singleuser.sh /opt/
COPY matcloud-jupyterhub-singleuser /opt/

# modify appmode loader
RUN jupyter notebook --generate-config
COPY static/custom.js /project/.jupyter/custom/

WORKDIR /project
CMD ["/opt/start-singleuser.sh"]

#EOF
