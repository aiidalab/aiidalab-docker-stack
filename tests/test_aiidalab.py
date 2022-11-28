import pytest
import requests
import json
from packaging.version import parse


def test_notebook_service_available(notebook_service):
    response = requests.get(f"{notebook_service}/")
    assert response.status_code == 200


def test_pip_check(aiidalab_exec):
    aiidalab_exec("pip check")


def test_aiidalab_available(aiidalab_exec, nb_user, variant):
    if "lab" not in variant:
        pytest.skip()
    output = aiidalab_exec("aiidalab --version", user=nb_user).decode().strip().lower()
    assert "aiidalab" in output


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).decode().strip()
    assert "conda activate tmp" in output


def test_correct_python_version_installed(aiidalab_exec, python_version):
    info = json.loads(aiidalab_exec("mamba list --json --full-name python").decode())[0]
    assert info["name"] == "python"
    assert parse(info["version"]) == parse(python_version)


def test_correct_aiida_version_installed(aiidalab_exec, aiida_version):
    info = json.loads(
        aiidalab_exec("mamba list --json --full-name aiida-core").decode()
    )[0]
    assert info["name"] == "aiida-core"
    assert parse(info["version"]) == parse(aiida_version)


def test_correct_aiidalab_version_installed(aiidalab_exec, aiidalab_version, variant):
    if "lab" not in variant:
        pytest.skip()
    info = json.loads(aiidalab_exec("mamba list --json --full-name aiidalab").decode())[
        0
    ]
    assert info["name"] == "aiidalab"
    assert parse(info["version"]) == parse(aiidalab_version)


def test_correct_aiidalab_home_version_installed(
    aiidalab_exec, aiidalab_home_version, variant
):
    if "lab" not in variant:
        pytest.skip()
    info = json.loads(
        aiidalab_exec("mamba list --json --full-name aiidalab-home").decode()
    )[0]
    assert info["name"] == "aiidalab-home"
    assert parse(info["version"]) == parse(aiidalab_home_version)


@pytest.mark.parametrize("package_manager", ["mamba", "pip"])
@pytest.mark.parametrize("incompatible_version", ["1.6.3"])
def test_prevent_installation_of_incompatible_aiida_version(
    aiidalab_exec, nb_user, aiida_version, package_manager, incompatible_version
):
    assert parse(aiida_version) != parse(incompatible_version)
    # Expected to succeed:
    aiidalab_exec(
        f"{package_manager} install aiida-core=={aiida_version}", user=nb_user
    )
    with pytest.raises(Exception):
        aiidalab_exec(
            f"{package_manager} install aiida-core={incompatible_version}", user=nb_user
        )


@pytest.mark.parametrize("package_manager", ["mamba", "pip"])
@pytest.mark.parametrize("incompatible_version", ["22.7.1"])
def test_prevent_installation_of_incompatible_aiidalab_version(
    aiidalab_exec,
    nb_user,
    package_manager,
    incompatible_version,
    variant,
):
    if "lab" not in variant:
        pytest.skip()
    with pytest.raises(Exception):
        aiidalab_exec(
            f"{package_manager} install aiidalab={incompatible_version}", user=nb_user
        )


def test_verdi_status(aiidalab_exec, nb_user):
    output = aiidalab_exec("verdi status", user=nb_user).decode().strip()
    assert "Connected to RabbitMQ" in output
    assert "Daemon is running" in output


def test_path_local_pip(aiidalab_exec, nb_user):
    """test that the pip local bin path ~/.local/bin is added to PATH"""
    output = aiidalab_exec("bash -c 'echo \"${PATH}\"'", user=nb_user).decode()
    assert f"/home/{nb_user}/.local/bin" in output
