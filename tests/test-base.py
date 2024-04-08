"""This module contains tests for the base image, which are AiiDA and package management related tests."""

import pytest
import json
from packaging.version import parse


@pytest.mark.parametrize("pkg_manager", ["pip", "mamba"])
def test_prevent_installation_of_aiida(
    aiidalab_exec, nb_user, aiida_version, pkg_manager
):
    """aiida-core is pinned to the exact version in the container,
    test that both pip and mamba refuse to install a different version"""

    incompatible_version = "2.3.0"
    assert parse(aiida_version) != parse(incompatible_version)

    # Expected to succeed, although should be a no-op.
    aiidalab_exec(f"{pkg_manager} install aiida-core=={aiida_version}", user=nb_user)
    with pytest.raises(Exception):
        aiidalab_exec(
            f"{pkg_manager} install aiida-core=={incompatible_version}",
            user=nb_user,
        )


def test_correct_python_version_installed(aiidalab_exec, python_version):
    info = json.loads(aiidalab_exec("mamba list --json --full-name python"))[0]
    assert info["name"] == "python"
    assert parse(info["version"]) == parse(python_version)


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).strip()
    assert "conda activate tmp" in output
    # New conda environments should be created in ~/.conda/envs/
    output = aiidalab_exec("conda env list", user=nb_user).strip()
    assert f"/home/{nb_user}/.conda/envs/tmp" in output


def test_correct_aiida_version_installed(aiidalab_exec, aiida_version):
    cmd = "mamba list --json --full-name aiida-core"
    info = json.loads(aiidalab_exec(cmd))[0]
    assert info["name"] == "aiida-core"
    assert parse(info["version"]) == parse(aiida_version)


def test_path_local_pip(aiidalab_exec, nb_user):
    """test that the pip local bin path ~/.local/bin is added to PATH"""
    output = aiidalab_exec("bash -c 'echo \"${PATH}\"'", user=nb_user)
    assert f"/home/{nb_user}/.local/bin" in output


def test_pip_user_install(aiidalab_exec, pip_install, nb_user):
    """Test that pip installs packages to ~/.local/ by default"""
    import email

    # We use 'tuna' as an example of python-only package without dependencies
    pkg = "tuna"
    pip_install(pkg)
    output = aiidalab_exec(f"pip show {pkg}")

    # `pip show` output is in the RFC-compliant email header format
    msg = email.message_from_string(output)
    assert msg.get("Location").startswith(f"/home/{nb_user}/.local/")
