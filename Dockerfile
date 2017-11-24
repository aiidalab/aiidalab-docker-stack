# Using ubuntu:latest to get recent versions of CP2K and QE.
#
# see also:
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile
#
FROM ubuntu:zesty

USER root

# install debian packages
RUN apt-get update && apt-get install -y --no-install-recommends \
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
RUN for name in SSSP_acc_PBE SSSP_acc_PBESOL SSSP_eff_PBE SSSP_eff_PBESOL; do  \
       wget http://www.materialscloud.ch/sssp/pseudos/${name}.tar.gz;          \
       tar -xvzf ${name}.tar.gz;                                               \
       rm -v ${name}.tar.gz;                                                   \
    done;                                                                      \
    chown -R root:root /opt/pseudos/;                                          \
    chmod -R +r /opt/pseudos/
# remove misplaced pseudo
RUN rm -vf /opt/pseudos/SSSP_eff_PBE/Be_ONCV_PBE-1.0.upf

## install rclone
WORKDIR /opt/rclone
RUN wget https://downloads.rclone.org/rclone-v1.38-linux-amd64.zip;  \
    unzip rclone-v1.38-linux-amd64.zip;                              \
    ln -s rclone-v1.38-linux-amd64/rclone .


## install PyPI packages for Pyhon 3
RUN pip3 install --upgrade         \
    'jupyterhub==0.8.0'            \
    'notebook==5.1.0'

## install PyPI packages for Pyhon 2.
## Using pip freeze to keep user visible software stack stable.
COPY requirements.txt /opt/
RUN pip2 install -r /opt/requirements.txt


# active ipython kernels
RUN python2 -m ipykernel install
RUN python3 -m ipykernel install


# enable Jupyter extensions
RUN jupyter nbextension enable  --sys-prefix --py widgetsnbextension && \
    jupyter nbextension enable  --sys-prefix --py pythreejs          && \
    jupyter nbextension enable  --sys-prefix --py nglview            && \
    jupyter nbextension enable  --sys-prefix --py bqplot             && \
    jupyter nbextension enable  --sys-prefix --py ipympl             && \
    jupyter nbextension install --sys-prefix --py fileupload         && \
    jupyter nbextension enable  --sys-prefix --py fileupload


# install Jupyter Appmode
# server runs python3, notebook runs python2 - need both
RUN pip2 install appmode==0.1.0                                          && \
    pip3 install appmode==0.1.0                                          && \
    jupyter nbextension     enable  --sys-prefix --py appmode            && \
    jupyter serverextension enable  --sys-prefix --py appmode


# install MolPad
WORKDIR /opt
RUN git clone https://github.com/oschuett/molview-ipywidget.git  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python2.7/dist-packages/molview_ipywidget  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python3.5/dist-packages/molview_ipywidget  && \
    jupyter nbextension     install --sys-prefix --py --symlink molview_ipywidget  && \
    jupyter nbextension     enable  --sys-prefix --py           molview_ipywidget

# create symlink for legacy workflows
RUN cd /usr/local/lib/python2.7/dist-packages/aiida/workflows; rm -rf user; ln -s /project/workflows user

# populate reentry cache
# https://pypi.python.org/pypi/reentry/
RUN reentry scan

# disable MPI warnings that confuse ASE
# https://www.mail-archive.com/users@lists.open-mpi.org/msg30611.html
RUN echo "btl_base_warn_component_unused = 0" >> /etc/openmpi/openmpi-mca-params.conf

# install Tini
# TODO: might not be needed in the future, Docker now has an init build-in
WORKDIR /opt
RUN wget https://github.com/krallin/tini/releases/download/v0.15.0/tini && \
    chmod +x /opt/tini
ENTRYPOINT ["/opt/tini", "--"]

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