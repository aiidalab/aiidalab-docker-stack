# Docker Stack for AiiDAlab

This repository contains the Dockerfile for the official AiiDAlab docker images.

Docker images are automatically built and pushed to Docker Hub at https://hub.docker.com/r/aiidalab/aiidalab-docker-stack with the following tags:

- `latest` –  the latest tagged release.
- `<version>` – a specific tagged release, example: `21.12.0`.
- `master`/`develop` – the latest commit on the corresponding branches with the same name.

# Get started

## Local deployment

To run AiiDAlab on your own workstation or laptop you can either
- run the image directly with: `docker run aiidalab-docker-stack -p 8888:8888`, or
- _(recommended)_ use the `aiidalab-launch` tool which is a thin docker wrapper.

The `aiidalab-launch` tool provides a convenient and robust method of both launching and managing one or multiple AiiDAlab instances on your computer.
To use it, simply install it via pip
```console
pip install aiidalab-launch
```
and then start AiiDAlab with
```console
aiidalab-launch start
```
Note: AiiDAlab will keep running until you explicitly stop it or shutdown/restart your computer.
In that case, you will have to run the `aiidalab-launch start` command again to restart AiiDAlab.

Please see `aiidalab-launch --help` for a full list of available commands and options.

## Cloud and other deployments

Please see the [AiiDAlab documentation](https://aiidalab.readthedocs.io/) for information on how to use and deploy AiiDAlab docker images in alternative ways.

## Citation

Users of AiiDAlab are kindly asked to cite the following publication in their own work:

A. V. Yakutovich et al., Comp. Mat. Sci. 188, 110165 (2021).
[DOI:10.1016/j.commatsci.2020.110165](https://doi.org/10.1016/j.commatsci.2020.110165)

# Acknowledgements

This work is supported by the [MARVEL National Centre for Competency in Research](<http://nccr-marvel.ch>)
funded by the [Swiss National Science Foundation](<http://www.snf.ch/en>), as well as by the [MaX
European Centre of Excellence](<http://www.max-centre.eu/>) funded by the Horizon 2020 EINFRA-5 program,
Grant No. 676598.

![MARVEL](miscellaneous/logos/MARVEL.png)
![MaX](miscellaneous/logos/MaX.png)
