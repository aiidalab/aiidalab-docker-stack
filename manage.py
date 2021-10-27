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
from subprocess import SubprocessError, run
from textwrap import wrap
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
@click.option("-p", "--project-name", help="Specify an alternative project name.")
@click.option(
    "--env-file",
    type=click.Path(dir_okay=False, writable=True, path_type=Path),
    default=".env",
    help="The path of the env-file to use for configuration.",
    show_default=True,
)
@click.option(
    "-v",
    "--verbose",
    count=True,
    help="Provide this option to increase the output verbosity of the launcher.",
)
@click.option(
    "--yes",
    is_flag=True,
    help="Automatically respond with yes to any prompts.",
)
@click.pass_context
def cli(ctx, develop, project_name, env_file, verbose, yes):

    # Specify the compose-files that will be merged to generate the final config.
    compose_file_args = ["-f", "docker-compose.yml"]
    if develop:
        compose_file_args.extend(["-f", "docker-compose.develop.yml"])

    # This command is to be used by all sub-commands.
    def _compose_cmd(args, **kwargs):
        args.insert(0, f"--env-file={env_file}")
        if project_name:
            args.insert(0, f"--project-name={project_name}")
        kwargs.setdefault("capture_output", not verbose)
        kwargs.setdefault("check", True)
        kwargs.setdefault("env", {})
        kwargs["env"].setdefault("PATH", os.environ["PATH"])
        return run(["docker-compose", *compose_file_args, *args], **kwargs)

    ctx.obj = dict()
    ctx.obj["compose_cmd"] = _compose_cmd
    ctx.obj["env_file"] = env_file
    ctx.obj["verbose"] = verbose
    ctx.obj["yes"] = yes


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
    help="Specify a path to a directory on a host system that is to be mounted "
    "as the home directory on the AiiDAlab service. Uses docker volume if not provided.",
)
@click.option(
    "--port",
    help="Port on which AiiDAlab can be accessed.",
)
@click.option(
    "--username", help="Specify the username to be used within the container."
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
@click.pass_context
def configure(ctx, home_dir, port, username, jupyter_token, app):
    """Configure the local AiiDAlab environment."""
    env_file = ctx.obj["env_file"]

    # First, specify the defaults.
    env = {
        "AIIDALAB_HOME_VOLUME": "aiidalab-home",
        "AIIDALAB_PORT": "8888",
        "AIIDALAB_DEFAULT_APPS": "aiidalab-widgets-base",
        "JUPYTER_TOKEN": token_hex(32),
        "SYSTEM_USER": "aiida",
    }

    # Next, update them with the currently stored values.
    env.update(dotenv_values(env_file))

    # Finally, update them with any of the values provided as arguments.
    provided = {
        "AIIDALAB_HOME_VOLUME": str(home_dir) if home_dir else None,
        "AIIDALAB_PORT": str(port) if port else None,
        "AIIDALAB_DEFAULT_APPS": " ".join(app),
        "JUPYTER_TOKEN": str(jupyter_token) if jupyter_token else None,
        "SYSTEM_USER": username or None,
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
@click.pass_context
def up(ctx, restart):
    """Start AiiDAlab on this host."""

    # Check for an '.env' file. The file can be automatically created via the
    # `configure` command.
    msg_warn_up_without_env_file = "\n".join(
        wrap(
            "Warning: Did not find an '.env' file in the current working directory. It "
            "is recommended to run the 'configure' command prior to first start. "
            "Continue anyways?"
        )
    )
    env_file = Path.cwd().joinpath(".env")
    if not env_file.exists() and not ctx.obj["yes"]:
        click.confirm(msg_warn_up_without_env_file, abort=True)

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

    # We display the entry point to the user by invoking the `status()`
    # function, which the user can also invoke directly via the `status`
    # sub-command.  We sleep briefly, as trying to determine the entry point
    # immediately after "upping" the service is prone to fail.
    sleep(0.5)
    ctx.invoke(status)


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
    if volumes and not ctx.obj["yes"]:
        click.confirm(
            "Are you sure you want to remove all volumes? "
            "This can lead to irreversible data loss!",
            abort=True,
        )

    _docker_compose(["down"] + (["--volumes"] if volumes else []))
    click.echo("AiiDAlab stopped.")


@cli.command("status")
@click.pass_context
def status(ctx):
    """Show status of the AiiDAlab instance.

    Shows the entrypoint for running instances.
    """
    _docker_compose = ctx.obj["compose_cmd"]

    try:
        _docker_compose(["exec", "aiidalab", "wait-for-services"])
        aiidalab_container_id = _get_service_container_id(_docker_compose, "aiidalab")
        config = json.loads(
            run(
                ["docker", "inspect", aiidalab_container_id],
                check=True,
                capture_output=True,
            ).stdout
        )[0]

        host_port = config["HostConfig"]["PortBindings"]["8888/tcp"][0]["HostPort"]
        for env in config["Config"]["Env"]:
            if "JUPYTER_TOKEN" in env:
                jupyter_token = env.split("=")[1]
                break
        else:
            raise RuntimeError("Failed to determine jupyter token.")
    except SubprocessError as error:
        click.echo(
            "Unable to communicate with the AiiDAlab container. Is it running? "
            "Use `up` to start it."
        )
    except (KeyError, IndexError) as error:
        raise click.ClickException(
            f"Failed to determine entry point due to error: '{error}'"
        )
    else:
        click.secho(
            f"Open this link in the browser to enter AiiDAlab:\n"
            f"http://localhost:{host_port}/?token={jupyter_token}",
            fg="green",
        )


if __name__ == "__main__":
    cli()
