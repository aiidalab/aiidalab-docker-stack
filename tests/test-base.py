"""This module contains tests for the base image, which are AiiDA and package management related tests."""

import pytest
import json
from packaging.version import parse


@pytest.mark.parametrize("incompatible_version", ["1.6.3"])
def test_prevent_pip_install_of_incompatible_aiida_version(
    aiidalab_exec, nb_user, aiida_version, incompatible_version
):
    package_manager = "pip"
    assert parse(aiida_version) != parse(incompatible_version)
    # Expected to succeed:
    aiidalab_exec(
        f"{package_manager} install aiida-core=={aiida_version}", user=nb_user
    )
    with pytest.raises(Exception):
        aiidalab_exec(
            f"{package_manager} install aiida-core=={incompatible_version}",
            user=nb_user,
        )


def test_correct_python_version_installed(aiidalab_exec, python_version):
    info = json.loads(aiidalab_exec("mamba list --json --full-name python").decode())[0]
    assert info["name"] == "python"
    assert parse(info["version"]) == parse(python_version)


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).decode().strip()
    assert "conda activate tmp" in output
    # New conda environments should be created in ~/.conda/envs/
    output = aiidalab_exec("conda env list", user=nb_user).decode().strip()
    assert f"/home/{nb_user}/.conda/envs/tmp" in output


def test_pip_check(aiidalab_exec):
    aiidalab_exec("pip check")


def test_correct_aiida_version_installed(aiidalab_exec, aiida_version):
    info = json.loads(
        aiidalab_exec("mamba list --json --full-name aiida-core").decode()
    )[0]
    assert info["name"] == "aiida-core"
    assert parse(info["version"]) == parse(aiida_version)


def test_path_local_pip(aiidalab_exec, nb_user):
    """test that the pip local bin path ~/.local/bin is added to PATH"""
    output = aiidalab_exec("bash -c 'echo \"${PATH}\"'", user=nb_user).decode()
    assert f"/home/{nb_user}/.local/bin" in output
