import json
import platform
from pathlib import Path

import docker
from doit.tools import title_with_actions
from dunamai import Version

_DOCKER_CLIENT = docker.from_env()
_DOCKER_ARCHITECTURE = _DOCKER_CLIENT.info()["Architecture"]

DOIT_CONFIG = {"default_tasks": ["build"]}

VERSION = Version.from_git().serialize().replace("+", "_")

_ARCH_MAPPING = {
    "x86_64": "amd64",
    "amd64": "amd64",
    "aarch64": "arm64",
}

ARCH = _ARCH_MAPPING.get(_DOCKER_ARCHITECTURE)

if ARCH is None:
    print(
        f"Unsupported architecture {_DOCKER_ARCHITECTURE} on platform {platform.system()}."
    )
    exit(1)

_REGISTRY_PARAM = {
    "name": "registry",
    "short": "r",
    "long": "registry",
    "type": str,
    "default": "",
    "help": "Specify the docker image registry (without the trailing slash).",
}

_ORGANIZATION_PARAM = {
    "name": "organization",
    "short": "o",
    "long": "organization",
    "type": str,
    "default": "aiidalab",
    "help": "Specify the docker image organization.",
}

_VERSION_PARAM = {
    "name": "version",
    "long": "version",
    "type": str,
    "default": VERSION,
    "help": (
        "Specify the version of the stack for building / testing. Defaults to a "
        "version determined from the state of the local git repository."
    ),
}

_ARCH_PARAM = {
    "name": "architecture",
    "long": "arch",
    "type": str,
    "default": ARCH,
    "help": "Specify the platform to build for. Examples: arm64, amd64.",
}

_TARGET_PARAM = {
    "name": "target",
    "long": "target",
    "short": "t",
    "type": str,
    "choices": (
        ("base", ""),
        ("base-with-services", ""),
        ("lab", ""),
        ("full-stack", ""),
    ),
    "default": "",
    "help": "Specify the target to build.",
}

_AIIDALAB_PORT_PARAM = {
    "name": "port",
    "short": "p",
    "long": "port",
    "type": int,
    "default": 8888,
    "help": "Specify the AiiDAlab host port.",
}


def task_build():
    """Build all docker images."""

    def generate_version_override(
        version, registry, targets, architecture, organization
    ):
        platforms = [f"linux/{architecture}"]
        overrides = {
            "VERSION": f":{version}",
            "REGISTRY": f"{registry}/",
            "ORGANIZATION": organization,
            "PLATFORMS": platforms,
        }
        # If no targets are specifies via cmdline, we'll build all images,
        # as specified in docker-bake.hcl
        if targets:
            overrides["TARGETS"] = targets

        Path("docker-bake.override.json").write_text(json.dumps(overrides))

    return {
        "actions": [
            generate_version_override,
            "docker buildx bake -f docker-bake.hcl -f build.json "
            "-f docker-bake.override.json "
            "--load",
        ],
        "title": title_with_actions,
        "params": [
            _ORGANIZATION_PARAM,
            _REGISTRY_PARAM,
            _VERSION_PARAM,
            _ARCH_PARAM,
            _TARGET_PARAM,
        ],
        "verbosity": 2,
    }


def task_tests():
    """Run tests with pytest."""

    def target_required(port, registry, version, target):  # noqa: ARG001
        if not target:
            print("ERROR: Target image must be with '--target' option for testing")
            return False
        return True

    return {
        "actions": [
            target_required,
            "AIIDALAB_PORT=%(port)i REGISTRY=%(registry)s/ VERSION=:%(version)s "
            "pytest -sv --target %(target)s",
        ],
        "params": [
            _AIIDALAB_PORT_PARAM,
            _REGISTRY_PARAM,
            _VERSION_PARAM,
            _TARGET_PARAM,
        ],
        "verbosity": 2,
    }


def task_up():
    """Start AiiDAlab server for testing."""

    def target_required(port, registry, version, target):  # noqa: ARG001
        if not target:
            print("ERROR: Target image must be provided with '--target' option")
            return False
        return True

    return {
        "actions": [
            target_required,
            "AIIDALAB_PORT=%(port)i REGISTRY=%(registry)s/ VERSION=:%(version)s "
            "docker compose -f stack/docker-compose.%(target)s.yml up --detach",
        ],
        "params": [
            _AIIDALAB_PORT_PARAM,
            _REGISTRY_PARAM,
            _VERSION_PARAM,
            _TARGET_PARAM,
        ],
        "verbosity": 2,
    }


def task_down():
    """Stop AiiDAlab server."""
    return {"actions": ["docker-compose down"], "verbosity": 2}
