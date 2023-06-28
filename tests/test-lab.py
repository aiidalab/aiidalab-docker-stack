import pytest
import json
from packaging.version import parse


def test_correct_aiidalab_version_installed(aiidalab_exec, aiidalab_version):
    info = json.loads(aiidalab_exec("mamba list --json --full-name aiidalab").decode())[
        0
    ]
    assert info["name"] == "aiidalab"
    assert parse(info["version"]) == parse(aiidalab_version)


def test_correct_aiidalab_home_version_installed(aiidalab_exec, aiidalab_home_version):
    info = json.loads(
        aiidalab_exec("mamba list --json --full-name aiidalab-home").decode()
    )[0]
    assert info["name"] == "aiidalab-home"
    assert parse(info["version"]) == parse(aiidalab_home_version)

@pytest.mark.parametrize("incompatible_version", ["22.7.1"])
def test_prevent_pip_install_of_incompatible_aiidalab_version(
    aiidalab_exec,
    nb_user,
    incompatible_version,
):
    package_manager = "pip"
    with pytest.raises(Exception):
        aiidalab_exec(
            f"{package_manager} install aiidalab=={incompatible_version}", user=nb_user
        )
