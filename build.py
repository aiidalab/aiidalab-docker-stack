#!/usr/bin/env python
import os
from pathlib import Path

import click
from yaml import SafeLoader, load

BUILD_CONFIG = load(Path("build.yml").read_text(), Loader=SafeLoader)


def get_organization():
    return BUILD_CONFIG["organization"]


def get_version():
    return BUILD_CONFIG["version"]


def get_tags():
    yield BUILD_CONFIG["version"]  # The version of the stack.
    # The versions of dependencies:
    for name, version in BUILD_CONFIG["versions"].items():
        yield f"{name}-{version}"


def get_docker_build_args():
    yield f"VERSION={BUILD_CONFIG['version']}"
    for name, version in BUILD_CONFIG["versions"].items():
        yield f"{name.upper()}_VERSION={version}"


@click.group()
def cli():
    pass


@cli.command()
@click.option(
    "--github-actions",
    is_flag=True,
    help="Output tags in a format convenient for GitHub actions.",
)
def tags(github_actions):
    if github_actions:
        enable = str(os.environ.get("GITHUB_REF_TYPE", None) == "tag").lower()
        click.echo(
            r"%0A".join(
                f"type=raw,enable={enable},event=tag,value={tag}" for tag in get_tags()
            )
        )
    else:
        click.echo("\n".join(get_tags()))


@cli.command()
@click.option(
    "--github-actions",
    is_flag=True,
    help="Output tags in a format convenient for GitHub actions.",
)
def docker_build_args(github_actions):
    if github_actions:
        click.echo(r"%0A".join(get_docker_build_args()))
    else:
        click.echo(" ".join(f"--build-arg {arg}" for arg in get_docker_build_args()))


if __name__ == "__main__":
    cli()
