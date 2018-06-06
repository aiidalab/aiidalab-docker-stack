# Using ubuntu:latest to get recent versions of CP2K and QE.
#
# see also:
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile
#
FROM ubuntu:17.10

USER root
RUN sed -i -e "s/\/\/archive\.ubuntu/\/\/au.archive.ubuntu/" /etc/apt/sources.list

# install debian packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update && apt-get install -y --no-install-recommends  \
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
    postgresql            \
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


# fix locals
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
WORKDIR /opt/rclone
RUN wget https://downloads.rclone.org/rclone-v1.38-linux-amd64.zip;  \
    unzip rclone-v1.38-linux-amd64.zip;                              \
    ln -s rclone-v1.38-linux-amd64/rclone .


## install PyPI packages for Python 3
RUN pip3 install --upgrade         \
    'tornado==4.5.3'               \
    'jupyterhub==0.8.1'            \
    'notebook==5.5.0'

## install PyPI packages for Python 2.
RUN pip2 install --process-dependency-links git+https://github.com/materialscloud-org/aiidalab-metapkg@v18.06.0rc1

## Get latest bugfixes from aiida-core
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
## TODO: might not be needed in the future, Docker now has an init build-in
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
COPY start-singleuser.sh /opt/
COPY matcloud-jupyterhub-singleuser /opt/
WORKDIR /project
CMD ["/opt/start-singleuser.sh"]

#EOF
