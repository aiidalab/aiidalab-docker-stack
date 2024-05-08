# Docker Stack for AiiDAlab

This repository contains the Dockerfiles for the official [AiiDAlab](https://www.aiidalab.net/) docker image stack.
All images are based on the [jupyter/minimal-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-minimal-notebook).

Image variants:
- `base` – A minimal image that comes with AiiDA pre-installed and an AiiDA profile set up.
- `base-with-services` – Like `base`, but AiiDA services (PostgreSQL and RabbitMQ) are installed on the container and automatically launched on startup.
- `lab` – Like `base`, but uses the AiiDAlab home app as the primary interface (the standard JupyterLab interface is also available).
- `full-stack` – Our most comprehensive image, like `lab`, but also comes with services pre-installed and launched.

Supported tags (released on [Docker Hub](https://hub.docker.com/r/aiidalab)):

- `edge` – the latest commit on the default branch (`main`)
- `latest` – the latest _regular_ release
- `aiida-$AIIDA_VERSION` – the _latest_ regular release with that AiiDA version (ex. `aiida-2.0.0`)
- `python-$PYTHON_VERSION` – the _latest_ regular release with that Python version (ex. `python-3.9.13`)
- `$version` – the version of a specific release (ex. `2022.1001`)

In addition, images are also released _internally_ on the [GitHub Container registry (ghcr.io)](https://github.com/orgs/aiidalab/packages?ecosystem=container).
Pull requests into the default branch are further released on ghcr.io with the `pr-###` tag to simplify the testing of development versions.

## Quickstart

You can launch a container based on one of our published images directly with [Docker](https://docs.docker.com/get-docker/), by executing for example the following command:

```console
docker run -it -p 8888:8888 aiidalab/full-stack
```
However, we recommend to use [AiiDAlab Launch](#deploy-aiidalab-with-aiidalab-launch) to run images locally for production environments.

_Note: On recent versions of Mac OS-X you will have to select a different port, since port 8888 is already in use by one of the system services._

## Known limitations

- Resetting the username and thus home directory location from the default (`jovyan`) via the `NB_USER` environment variable is currently not supported (#297).

## Development

### Development environment

The repository uses the [doit automation tool](https://pydoit.org/) to automate tasks related to this repository, including _building_, _testing_, and _locally deploying_ Docker images with docker-compose.

To use this system, setup a build end testing environment and install the dependencies with:

```console
pip install -r requirements-dev.txt
```

### Build images locally

To build the images, run `doit build` (tested with *docker buildx* version v0.8.2).

The build system will attempt to detect the local architecture and automatically build images for it (tested with amd64 and arm64).
All commands `build`, `tests`, and `up` will use the locally detected platform and use a version tag based on the state of the local git repository.
However, you can also specify a custom platform or version with the `--platform` and `--version` parameters, example: `doit build --arch=arm64 --version=my-version`.

You can specify target stacks to build with `--target`, example: `doit build --target base --target full-stack`.

### Run automated tests

To run tests, first build the images as described in the previous section.
Then run the automated tests with `doit tests`.

Tip: The [continuous integration](#continuous-integration) workflow will build, release (at `ghcr.io/aiidalab/*:pr-###`), and test images for all pull requests into the default branch.

For manual testing, you can start the images with `doit up`, however we recommend to use [aiidalab-launch](#deploy-aiidalab-with-aiidalab-launch) to setup a production-ready local deployment.

### Continuous integration

Images are built for `linux/amd64` and `linux/arm64` during continuous integration for all pull requests into the default branch and pushed to the GitHub Container Registry (ghcr.io) with tags `ghcr.io/aiidalab/*:pr-###`.
You can run automated or manual tests against those images by specifying the registry and version for both the `up` and `tests` commands, example: `doit up --registry=ghcr.io/ --version=pr-123`.
Note: You may have to [log into the registry first](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry).

### Creating a release

We distinguish between _regular_ releases and _special_ releases, where the former follow the standard versioning scheme (`v2022.1001`) and the latter would be specific to a certain use case, e.g., a workshop with dedicated requirements.
To create a regular release, set up a development environment, and then use `bumpver`:
```console
bumpver update
```
This will update the README.md file, make a commit, tag it, and then push both to the repository to kick off the build and release flow.

To create a _special_ release, simply tag it with a tag name of your choice with the exception that it cannot start with the character `v`.

## Deploy AiiDAlab with aiidalab-launch

The [aiidalab-launch](https://github.com/aiidalab/aiidalab-launch) tool provides a convenient and robust method of both launching and managing one or multiple AiiDAlab instances on your computer.
To use it, simply install it via pipx
```console
pipx install aiidalab-launch
```
and then start AiiDAlab container with
```console
aiidalab-launch start
```
Note: AiiDAlab will keep running until you explicitly stop it with `aiidalab-launch stop` or shutdown/restart your computer.

Please see `aiidalab-launch --help` for a full list of available commands and options.

### Cloud and other deployments

Please see the [AiiDAlab documentation](https://aiidalab.readthedocs.io/) for information on how to use and deploy AiiDAlab docker images in alternative ways.

## Citation

Users of AiiDAlab are kindly asked to cite the following publication in their own work:

A. V. Yakutovich et al., Comp. Mat. Sci. 188, 110165 (2021).
[DOI:10.1016/j.commatsci.2020.110165](https://doi.org/10.1016/j.commatsci.2020.110165)

## Acknowledgements

This work is supported by the [MARVEL National Centre for Competency in Research](<https://nccr-marvel.ch>)
funded by the [Swiss National Science Foundation](<https://www.snf.ch/en>), as well as by the [MaX
European Centre of Excellence](<https://www.max-centre.eu/>) funded by the Horizon 2020 EINFRA-5 program,
Grant No. 676598.

![MARVEL](miscellaneous/logos/MARVEL.png)
![MaX](miscellaneous/logos/MaX.png)
