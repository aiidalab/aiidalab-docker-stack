import json
import platform
from pathlib import Path

import docker
from dunamai import Version

_DOCKER_CLIENT = docker.from_env()
_DOCKER_ARCHITECTURE = _DOCKER_CLIENT.info()["Architecture"]

DOIT_CONFIG = {"default_tasks": ["build"]}

VERSION = Version.from_git().serialize().replace("+", "_")
PLATFORM = {"aarch64": "linux/arm64"}.get(_DOCKER_ARCHITECTURE, _DOCKER_ARCHITECTURE)


_REGISTRY_PARAM = {
    "name": "registry",
    "short": "r",
    "long": "registry",
    "type": str,
    "default": "",
    "help": "Specify the docker image registry.",
}

_VERSION_PARAM = {
    "name": "version",
    "long": "version",
    "type": "str",
    "default": VERSION,
    "help": (
        "Specify the version of the stack for building / testing. Defaults to a "
        "version determined from the state of the local git repository."
    ),
}


def task_build():
    """Build all docker images."""

    def generate_version_override(version):
        Path("docker-bake.override.json").write_text(json.dumps(dict(VERSION=version)))

    return {
        "actions": [
            generate_version_override,
            "docker buildx bake -f docker-bake.hcl -f build.json "
            "-f docker-bake.override.json "
            "--set '*.platform=%(platform)s' "
            "--load",
        ],
        "params": [
            _REGISTRY_PARAM,
            _VERSION_PARAM,
            {
                "name": "platform",
                "long": "platform",
                "type": str,
                "default": PLATFORM or "linux/amd64",
                "help": "Specify the platform to build for. Examples: linux/amd64 linux/arm64",
            },
        ],
        "verbosity": 2,
    }


def task_tests():
    """Run tests with pytest."""

    return {
        "actions": ["REGISTRY=%(registry)s VERSION=:%(version)s pytest -v"],
        "params": [_REGISTRY_PARAM, _VERSION_PARAM],
        "verbosity": 2,
    }


def task_up():
    """Start AiiDAlab server for testing."""
    return {
        "actions": [
            "AIIDALAB_PORT=%(port)i REGISTRY=%(registry)s VERSION=:%(version)s "
            "docker-compose up --detach"
        ],
        "params": [
            {
                "name": "port",
                "short": "p",
                "long": "port",
                "type": int,
                "default": 8888,
                "help": "Specify the AiiDAlab host port.",
            },
            _REGISTRY_PARAM,
            _VERSION_PARAM,
        ],
        "verbosity": 2,
    }


def task_down():
    """Stop AiiDAlab server."""
    return {"actions": ["docker-compose down"], "verbosity": 2}
