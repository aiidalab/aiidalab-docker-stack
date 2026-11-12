"""Exercise SSH startup repair with disposable keys in the test container."""

import shlex

import pytest

PREPARE_HOME_HOOK = "/usr/local/bin/before-notebook.d/10_prepare-home-config.sh"


@pytest.fixture
def ssh_home(aiidalab_exec, nb_user):
    directory = f"/home/{nb_user}/.ssh"

    def run(script):
        return aiidalab_exec(f"bash -c {shlex.quote(script)}", user=nb_user)

    temporary = run("mktemp -d /tmp/aiidalab-ssh-test.XXXXXX").strip()
    run(f"mv {directory} {temporary}/original")
    try:
        run(
            f"mkdir -m 700 {directory}; "
            f"ssh-keygen -q -t rsa -b 2048 -m PEM -N '' -f {directory}/id_rsa; "
            f"touch {directory}/known_hosts"
        )
        yield directory, run
    finally:
        run(
            f"if [ -f {directory}/agent-environment ]; then "
            f"source {directory}/agent-environment >/dev/null; "
            "ssh-agent -k >/dev/null 2>&1 || true; fi; "
            f"rm -rf {directory}; mv {temporary}/original {directory}; "
            f"rm -rf {temporary}"
        )


def test_ssh_permissions_after_remount(ssh_home):
    directory, run = ssh_home
    private_key = f"{directory}/id_rsa"
    run(f"chmod 2770 {directory}; chmod 660 {private_key}")

    for _ in range(2):
        run(f"set -e; source {PREPARE_HOME_HOOK}")
        assert run(f"stat -c %a {directory}").strip() == "700"
        assert run(f"stat -c %a {private_key}").strip() == "600"
        run(f"ssh-keygen -y -P '' -f {private_key} >/dev/null")
