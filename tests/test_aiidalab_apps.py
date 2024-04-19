import pytest

pytestmark = pytest.mark.integration
# Integration tests for the full-stack image.
# Here we make sure we can install aiidalab-widgets-base and aiidalab-qe apps
TESTED_TARGETS = "full-stack"


@pytest.fixture(autouse=True)
def skip_if_incompatible_target(target):
    if target in TESTED_TARGETS:
        yield
    else:
        pytest.skip()


@pytest.fixture(scope="function")
def generate_aiidalab_install_output(aiidalab_exec, nb_user):
    def _generate_aiidalab_install_output(package_name):
        cmd = f"aiidalab install --yes --pre {package_name}"
        output = aiidalab_exec(cmd, user=nb_user).strip()

        output += aiidalab_exec("pip check", user=nb_user).strip()

        yield output
        # Now, ninstall the package to make sure the test is repeatable.
        # NOTE: This will only uninstall the package itself, not its dependencies!
        # Since the dependencies are installed via pip, this is basically a pip limitation
        # that would be hard to workaround here.
        app_name = package_name.split("@")[0]
        aiidalab_exec(f"aiidalab uninstall --yes --force {app_name}", user=nb_user)

    return _generate_aiidalab_install_output


@pytest.mark.parametrize("package_name", ["aiidalab-widgets-base", "quantum-espresso"])
def test_install_apps_from_stable(generate_aiidalab_install_output, package_name):
    """Test that apps can be installed from app store."""
    output = generate_aiidalab_install_output(package_name)

    assert "ERROR" not in output
    assert "dependency conflict" not in output
    assert f"Installed '{package_name}' version" in output
    assert "No broken requirements found" in output


@pytest.mark.parametrize("repo_name", ["aiidalab-widgets-base", "aiidalab-qe"])
def test_install_apps_from_default_branch(generate_aiidalab_install_output, repo_name):
    """Test that apps can be installed from the default branch of the repository."""
    package = f"{repo_name}@git+https://github.com/aiidalab/{repo_name}.git"
    output = generate_aiidalab_install_output(package)

    assert "ERROR" not in output
    assert "dependency conflict" not in output
    assert f"Installed '{repo_name}' version" in output
    assert "No broken requirements found" in output
