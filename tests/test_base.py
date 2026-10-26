"""This module contains tests for the base image, which are AiiDA and package management related tests."""

import email

import pytest
from packaging.version import parse


@pytest.fixture
def venv(tmp_path, aiidalab_exec):
    venv_path = tmp_path / ".venv"
    aiidalab_exec(f"python -m venv {venv_path}")
    return venv_path


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
    with pytest.raises(Exception):  # noqa: B017
        aiidalab_exec(
            f"{pkg_manager} install aiida-core=={incompatible_version}",
            user=nb_user,
        )


@pytest.mark.parametrize("pkg_manager", ["pip", "mamba"])
def test_prevent_notebook_upgrade(aiidalab_exec, nb_user, pkg_manager):
    """jupyter-notebook is pinned to the exact version in the container,
    test that both pip and mamba refuse to update to v7 of the notebook."""

    incompatible_version = "7"
    with pytest.raises(Exception):  # noqa: B017
        aiidalab_exec(
            f"{pkg_manager} install notebook=={incompatible_version}",
            user=nb_user,
        )


def test_python_version(package_info, python_version):
    info = package_info("python")
    assert parse(info["version"]) == parse(python_version)


def test_pip_version(package_info):
    """We update pip to latest version when building the image,
    test that we're not using and old pip version"""
    info = package_info("pip")
    # pip==25.2 is the last version on conda-forge that supports python 3.9
    # We should bump the asserted minimum version to 26.0 once we upgrade the image to python 3.12
    assert parse(info["version"]) >= parse("25.2")


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).strip()
    assert "conda activate tmp" in output
    # New conda environments should be created in ~/.conda/envs/
    output = aiidalab_exec("conda env list", user=nb_user).strip()
    assert f"/home/{nb_user}/.conda/envs/tmp" in output


def test_aiida_version(package_info, aiida_version):
    info = package_info("aiida-core")
    assert parse(info["version"]) == parse(aiida_version)


def test_path_local_pip(aiidalab_exec, nb_user):
    """test that the pip local bin path ~/.local/bin is added to PATH"""
    output = aiidalab_exec("bash -c 'echo \"${PATH}\"'", user=nb_user)
    assert f"/home/{nb_user}/.local/bin" in output


def test_pip_user_install(aiidalab_exec, pip_install, nb_user):
    """Test that pip installs packages to ~/.local/ by default"""
    # We use 'tuna' as an example of python-only package without dependencies
    pkg = "tuna"
    pip_install(pkg)
    output = aiidalab_exec(f"pip show {pkg}")

    # `pip show` output is in the RFC-compliant email header format
    msg = email.message_from_string(output)
    assert msg.get("Location").startswith(f"/home/{nb_user}/.local/")


def test_pip_install_in_venv(aiidalab_exec, venv, nb_user):
    """Test that pip installs packages to an activated venv"""

    pkg = "tuna"
    pip = venv / "bin/pip"

    aiidalab_exec(f"{pip} install {pkg}")

    output = aiidalab_exec(f"{pip} show {pkg}")
    msg = email.message_from_string(output)
    assert msg.get("Location").startswith(f"{venv}/lib")


FACTORY_RESET_HOOK = "/usr/local/bin/before-notebook.d/05_factory-reset.sh"
FACTORY_RESET_MARKER = "factory-reset-test-marker"


@pytest.fixture
def factory_reset(aiidalab_exec, nb_user):
    """Run the factory reset hook directly, sourced from a `set -e` shell
    as the container start script does, and restore ~/.local afterwards."""
    home = f"/home/{nb_user}"

    def run_bash(script, **kwargs):
        return aiidalab_exec(f"bash -c '{script}'", user=nb_user, **kwargs)

    def _factory_reset(request=None):
        if request is not None:
            run_bash(request)
        return run_bash(f"set -e; source {FACTORY_RESET_HOOK}")

    def home_entries():
        return set(run_bash(f"ls -A {home}").split())

    _factory_reset.run_bash = run_bash
    _factory_reset.home_entries = home_entries

    assert not any(e.startswith(".local~") for e in home_entries())
    run_bash(f"mkdir -p {home}/.local && touch {home}/.local/{FACTORY_RESET_MARKER}")

    yield _factory_reset

    run_bash(
        f"chmod u+w {home}; rm -rf {home}/AIIDALAB_FACTORY_RESET; "
        f'for b in {home}/.local~*; do [ -d "$b" ] || continue; '
        f'rm -rf {home}/.local; mv -T "$b" {home}/.local; done; '
        f"rm -f {home}/.local/{FACTORY_RESET_MARKER}"
    )


def test_factory_reset_not_requested(factory_reset):
    entries = factory_reset.home_entries()
    assert factory_reset() == ""
    assert factory_reset.home_entries() == entries


def test_factory_reset_local(factory_reset, nb_user):
    output = factory_reset(f"echo local > /home/{nb_user}/AIIDALAB_FACTORY_RESET")
    assert "Move ~/.local/" in output

    entries = factory_reset.home_entries()
    assert "AIIDALAB_FACTORY_RESET" not in entries
    assert ".local" not in entries
    (backup,) = (e for e in entries if e.startswith(".local~"))
    assert FACTORY_RESET_MARKER in factory_reset.run_bash(
        f"ls -A /home/{nb_user}/{backup}"
    )


def test_factory_reset_unknown_mode(factory_reset, nb_user):
    output = factory_reset(f"echo foo > /home/{nb_user}/AIIDALAB_FACTORY_RESET")
    assert "Unknown reset mode (foo)" in output

    entries = factory_reset.home_entries()
    assert "AIIDALAB_FACTORY_RESET" not in entries
    assert ".local" in entries


@pytest.mark.parametrize(
    "request_cmd",
    [
        "mkdir {reset_file}",
        "mkfifo {reset_file}",
        "echo local > {home}/target && ln -s {home}/target {reset_file}",
    ],
    ids=["directory", "fifo", "symlink"],
)
def test_factory_reset_not_regular_file(factory_reset, nb_user, request_cmd):
    home = f"/home/{nb_user}"
    reset_file = f"{home}/AIIDALAB_FACTORY_RESET"
    try:
        output = factory_reset(request_cmd.format(home=home, reset_file=reset_file))
        assert "is not a regular file" in output

        entries = factory_reset.home_entries()
        assert "AIIDALAB_FACTORY_RESET" in entries
        assert ".local" in entries
    finally:
        factory_reset.run_bash(f"rm -f {home}/target")


def test_factory_reset_failed_move(factory_reset, nb_user):
    """A failed reset aborts startup and keeps the request for the next start."""
    home = f"/home/{nb_user}"
    factory_reset.run_bash(f"echo local > {home}/AIIDALAB_FACTORY_RESET")
    # Moving ~/.local requires write permission on the home directory.
    factory_reset.run_bash(f"chmod u-w {home}")
    with pytest.raises(Exception):  # noqa: B017
        factory_reset()
    factory_reset.run_bash(f"chmod u+w {home}")

    entries = factory_reset.home_entries()
    assert "AIIDALAB_FACTORY_RESET" in entries
    assert ".local" in entries
# First Mozilla CA bundle that drops the compromised eMudhra roots,
# see https://emudhra.we-have-a-problem.com/
EMUDHRA_FIXED_CA_BUNDLE = "2026.10.23"
# External incident test site; remove these tests once it goes offline.
EMUDHRA_TEST_URLS = [
    "https://dv-g3b-emudhra.we-have-a-problem.com/",
    "https://dv-g3b-aaa-emudhra.we-have-a-problem.com/",
    "https://dv-g3b-noct-emudhra.we-have-a-problem.com/",
    "https://dv-g3b-aaa-noct-emudhra.we-have-a-problem.com/",
]


@pytest.mark.parametrize("cert_package", ["certifi", "ca-certificates"])
def test_cert_packages_updated(package_info, cert_package):
    info = package_info(cert_package)
    assert parse(info["version"]) >= parse(EMUDHRA_FIXED_CA_BUNDLE)


@pytest.mark.parametrize("test_url", EMUDHRA_TEST_URLS)
@pytest.mark.parametrize(
    "client",
    [
        # OS trust store (apt ca-certificates)
        "/usr/bin/curl --silent --show-error --connect-timeout 10 --max-time 30",
        # conda OpenSSL trust store (conda-forge ca-certificates)
        'python -c "import sys, urllib.request; urllib.request.urlopen(sys.argv[1], timeout=30)"',
        # requests (certifi)
        'python -c "import sys, requests; requests.get(sys.argv[1], timeout=30)"',
    ],
)
def test_emudhra_mitigation(aiidalab_exec, client, test_url):
    """Test that all trust stores in the image reject the compromised eMudhra roots

    Per https://emudhra.we-have-a-problem.com/#check
    """
    output = aiidalab_exec(f"sh -c '{client} {test_url} 2>&1; true'")

    assert "unable to get local issuer certificate" in output, output
