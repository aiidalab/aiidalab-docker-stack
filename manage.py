#!/usr/bin/env python
"""Convenience script wrapper to start and stop AiiDAlab via docker-compose.

Authors:
    * Carl Simon Adorf <simon.adorf@epfl.ch>
"""
import json
import os
import re
from collections import OrderedDict
from pathlib import Path
from secrets import token_hex
from subprocess import run
from time import sleep

import click
from dotenv import dotenv_values


def _get_service_container_id(docker_compose, service):
    return (
        docker_compose(["ps", "-q", service], capture_output=True)
        .stdout.decode()
        .strip()
    )


def _service_is_up(docker_compose, service):
    service_container_id = _get_service_container_id(docker_compose, "aiidalab")
    if service_container_id:
        running_containers = (
            run(["docker", "ps", "-q", "--no-trunc"], capture_output=True)
            .stdout.decode()
            .strip()
            .splitlines()
        )
        return service_container_id in running_containers
    else:
        return False


@click.group()
@click.option(
    "--develop",
    is_flag=True,
    help="Use this option to build AiiDAlab with development versions.",
)
@click.option(
    "-v",
    "--verbose",
    count=True,
    help="Provide this option to increase the output verbosity of the launcher.",
)
@click.pass_context
def cli(ctx, develop, verbose):

    # Specify the compose-files that will be merged to generate the final config.
    compose_file_args = ["-f", "docker-compose.yml"]
    if develop:
        compose_file_args.extend(["-f", "docker-compose.develop.yml"])

    # This command is to be used by all sub-commands.
    def _compose_cmd(args, **kwargs):
        kwargs.setdefault("capture_output", not verbose)
        kwargs.setdefault("check", True)
        kwargs.setdefault("env", {})
        kwargs["env"].setdefault("PATH", os.environ["PATH"])
        return run(["docker-compose", *compose_file_args, *args], **kwargs)

    ctx.obj = dict()
    ctx.obj["compose_cmd"] = _compose_cmd
    ctx.obj["verbose"] = verbose


@cli.command()
@click.pass_context
def show_config(ctx):
    """Show the merged docker-compose config."""
    _docker_compose = ctx.obj["compose_cmd"]
    click.echo(_docker_compose(["config"], capture_output=True).stdout)


@cli.command()
@click.option(
    "--home-dir",
    type=click.Path(),
    # default="aiidalab-home",
    help="Specify a path to a directory on a host system that is to be mounted "
    "as the home directory on the AiiDAlab service. Uses docker volume if not provided.",
)
@click.option(
    "--port",
    # default=8888,
    help="Port on which AiiDAlab can be accessed.",
    show_default=True,
)
@click.option(
    "--jupyter-token",
    help="A secret token that is needed to access AiiDAlab for the first time. "
    "Defaults to a random string if not provided (recommended).",
)
@click.option(
    "--app",
    multiple=True,
    help="Specify app to install on first server start, using the same syntax as "
    "`aiidalab install`. This option can be used multiple times to specify "
    "multiple default apps.",
)
@click.option(
    "--env-file",
    type=click.Path(dir_okay=False, writable=True, path_type=Path),
    default=".env",
    help="The path of the env-file to use for configuration.",
    show_default=True,
)
@click.pass_context
def configure(ctx, home_dir, port, jupyter_token, app, env_file):
    """Configure the local AiiDAlab environment."""
    # First, specify the defaults.
    env = OrderedDict(
        [
            ("AIIDALAB_HOME", "aiidalab-home"),
            ("AIIDALAB_PORT", "8888"),
            ("AIIDALAB_DEFAULT_APPS", "aiidalab-widgets-base"),
            ("JUPYTER_TOKEN", token_hex(32)),
        ]
    )

    # Next, update them with the currently stored values.
    env.update(dotenv_values(env_file))

    # Finally, update them with any of the values provided as arguments.
    provided = {
        "AIIDALAB_HOME": str(home_dir) if home_dir else None,
        "AIIDALAB_PORT": str(port) if port else None,
        "AIIDALAB_DEFAULT_APPS": " ".join(app),
    }
    env.update({key: value for key, value in provided.items() if value})

    # Write environment to the env_file.
    env_file.write_text(
        "\n".join(f"{key}={value}" for key, value in env.items()) + "\n"
    )
    click.echo(f"Written configuration to '{env_file}'.")


@cli.command()
@click.option(
    "--restart", is_flag=True, help="Restart AiiDAlab in case that it is already up."
)
@click.option(
    "--reset",
    type=click.Choice(["apps", "full"], case_sensitive=False),
    help="Reset the environment upon server (re)start. Warning! This option can lead to irreversible data loss!",
)
@click.pass_context
def up(ctx, restart, reset):
    """Start AiiDAlab on this host."""

    # Check for an '.env' file. The file can be automatically created via the
    # `configure` command.
    env_file = Path.cwd().joinpath(".env")
    if not env_file.exists():
        click.secho(
            f"Did not find a {env_file.relative_to(Path.cwd())} file. "
            "It is recommended to run the `configure` command prior to start "
            "for reproducible environments.",
            fg="yellow",
        )

    # Get the `docker-compose` proxy command from the global context.
    _docker_compose = ctx.obj["compose_cmd"]

    # Check if server is already started.
    if not restart and _service_is_up(_docker_compose, "aiidalab"):
        click.echo(
            "Service is already running. Use the `--restart` option to force a restart."
        )

    # Actually run the `docker-compose up` command.
    click.echo("Starting AiiDAlab (this can take multiple minutes) ...")
    _docker_compose(
        ["up", "--detach", "--build"] + (["--force-recreate"] if restart else [])
    )

    # We display the entry point to the user by invoking the `show_entrypoint()`
    # function, which the user can also invoke directly via the `info`
    # sub-command.  We sleep briefly, as trying to determine the entry point
    # immediately after "upping" the service is prone to fail.
    sleep(0.5)
    ctx.invoke(show_entrypoint)


@cli.command()
@click.option(
    "-v",
    "--volumes",
    is_flag=True,
    help="In addition to stopping the service, also remove any volumes. "
    "Warning: This can lead to irreversible data loss!",
)
@click.pass_context
def down(ctx, volumes):
    """Stop AiiDAlab on this host.

    This is a thin wrapper around `docker-compose down`.
    """
    _docker_compose = ctx.obj["compose_cmd"]
    if volumes and not click.confirm(
        "Are you sure you want to remove all volumes? "
        "This can lead to irreversible data loss!"
    ):
        click.echo("Exiting.")
        return

    _docker_compose(["down"] + (["--volumes"] if volumes else []))
    click.echo("AiiDAlab stopped.")


@cli.command("info")
@click.pass_context
def show_entrypoint(ctx):
    """Show entrypoint for a currently running AiiDAlab service."""
    _docker_compose = ctx.obj["compose_cmd"]

    if not _service_is_up(_docker_compose, "aiidalab"):
        raise click.ClickException(
            "AiiDAlab not running, use the 'up' command to start it."
        )

    _docker_compose(["exec", "aiidalab", "wait-for-services"])
    aiidalab_container_id = _get_service_container_id(_docker_compose, "aiidalab")
    try:
        config = json.loads(
            run(
                ["docker", "inspect", aiidalab_container_id],
                check=True,
                capture_output=True,
            ).stdout
        )[0]["Config"]
        port_match = re.match(r"(\d+)\/tcp", list(config["ExposedPorts"])[0])
        if not port_match:
            raise RuntimeError("Failed to determine exposed port.")
        exposed_port = int(port_match.groups()[0])
        env = config["Env"]
        for env in config["Env"]:
            if "JUPYTER_TOKEN" in env:
                jupyter_token = env.split("=")[1]
                break
        else:
            raise RuntimeError("Failed to determine jupyter token.")
    except (KeyError, IndexError) as error:
        raise click.ClickException(
            f"Failed to determine entry point due to error: '{error}'"
        )

    click.secho(f"Open this link in the browser to enter AiiDAlab:", fg="green")
    click.secho(f"http://localhost:{exposed_port}/?token={jupyter_token}", fg="green")


if __name__ == "__main__":
    cli()
