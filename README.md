# Docker Stack for AiiDAlab

This repo contains the Docker file used in the [AiiDAlab](https://www.materialscloud.org/aiidalab).

Docker images are available from Dockerhub via `docker pull aiidalab/aiidalab-docker-stack:latest`.
See [aiidalab/aiidalab-docker-stack](https://hub.docker.com/repository/docker/aiidalab/aiidalab-docker-stack) for a list of available tags.

# Documentation

## Local deployment

To launch a local instance of AiiDAlab, first clone this repository, e.g., with
```console
git clone https://github.com/aiidalab/aiidalab-docker-stack.git
cd aiidalab-docker-stack
```
and then install the Python requirements needed to run the manage script:
```
pip install -r requirements-manage.txt
```

Before starting AiiDAlab, it is recommended to configure it for your needs.
For example, to mount the AiiDAlab home directory on your local host at `~/aiidalab` instead of using a Docker volume, execute:
```console
./manage.py configure --home-dir=~/aiidalab
```
This creates a `.env` file in the local directory that stores the provided settings.

You can then launch your local AiiDAlab deployment with:
```console
$ ./manage.py up
```
You should see output similar to this:
```
Starting AiiDAlab (this can take multiple minutes) ...
Open this link in the browser to enter AiiDAlab:
http://localhost:8888/?token=be20d9872d...
```

Note: AiiDAlab will keep running until you shutdown or restart the host computer, in which case, you will have to run the `up` command again to restart AiiDAlab.

Please see `./manage.py --help` for a full list of available commands.

## Development deployment

For a local development deployment, run
```console
./manage.py --develop up
```

This will build and start an image where the `aiidalab` package, the `aiidalab-widgets-base` library, and the `aiidalab-home` app are installed with their latest development versions instead of their latest release versions.

## Other deployments

The `manage.py` script uses docker-compose to manage the local AiiDAlab deployment.
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
