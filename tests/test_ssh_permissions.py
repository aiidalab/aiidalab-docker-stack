"""Exercise SSH startup repair with disposable keys in the test container."""

import shlex

import pytest

PREPARE_HOME_HOOK = "/usr/local/bin/before-notebook.d/10_prepare-home-config.sh"


@pytest.fixture
def ssh_home(aiidalab_exec, nb_user):
    directory = f"/home/{nb_user}/.ssh"

    def run(script, **kwargs):
        return aiidalab_exec(f"bash -c {shlex.quote(script)}", user=nb_user, **kwargs)

    temporary = run("mktemp -d /tmp/aiidalab-ssh-test.XXXXXX").strip()
    run(f"mv {directory} {temporary}/original")
    try:
        run(
            f"mkdir -m 700 {directory}; "
            f"ssh-keygen -q -t rsa -b 2048 -m PEM -N '' -f {directory}/id_rsa; "
            f"touch {directory}/known_hosts"
        )
        yield directory, temporary, run
    finally:
        run(
            f"if [ -f {directory}/agent-environment ]; then "
            f"source {directory}/agent-environment >/dev/null; "
            "ssh-agent -k >/dev/null 2>&1 || true; fi; "
            f"rm -rf {directory}; mv {temporary}/original {directory}; "
            f"rm -rf {temporary}"
        )


def prepare_home(run):
    return run(f"set -e; source {PREPARE_HOME_HOOK} 2>&1; echo HOOK_COMPLETED")


def checksum(run, path):
    return run(f"sha256sum {shlex.quote(path)}").split()[0]


def mode(run, path):
    return run(f"stat -c %a {shlex.quote(path)}").strip()


def test_ssh_permissions_after_remount(ssh_home):
    directory, _, run = ssh_home
    custom = f"{directory}/cluster key"
    nested = f"{directory}/identities/secondary"
    run(
        f"mkdir {directory}/identities; "
        f"ssh-keygen -q -t ed25519 -N '' -f {shlex.quote(custom)}; "
        f"ssh-keygen -q -t ed25519 -N '' -f {nested}"
    )
    keys = [f"{directory}/id_rsa", custom, nested]
    hashes = [checksum(run, key) for key in keys]
    run(
        f"chmod 2770 {directory} {directory}/identities; "
        f"find {directory} -type f -exec chmod 660 {{}} +"
    )
    assert (
        run(
            f"ssh-keygen -y -P '' -f {shlex.quote(custom)} >/dev/null 2>&1; echo $?"
        ).strip()
        == "255"
    )

    for _ in range(2):
        assert "HOOK_COMPLETED" in prepare_home(run)
        assert mode(run, directory) == "700"
        assert mode(run, f"{directory}/identities") == "700"
        for key, digest in zip(keys, hashes):
            assert mode(run, key) == "600"
            assert checksum(run, key) == digest
            run(f"ssh-keygen -y -P '' -f {shlex.quote(key)} >/dev/null")
        run(
            f"source {directory}/agent-environment >/dev/null; "
            f"ssh-add {' '.join(shlex.quote(key) for key in keys)} >/dev/null 2>&1"
        )


def test_ssh_first_start_and_existing_key(ssh_home):
    directory, _, run = ssh_home
    run(f"rm -rf {directory}")
    prepare_home(run)
    assert int(mode(run, directory), 8) & 0o777 == 0o700
    assert mode(run, f"{directory}/id_rsa") == "600"
    digest = checksum(run, f"{directory}/id_rsa")
    prepare_home(run)
    assert checksum(run, f"{directory}/id_rsa") == digest


def test_ssh_secure_entries_are_unchanged(ssh_home):
    directory, _, run = ssh_home
    run(
        f"chmod 400 {directory}/id_rsa; chmod 600 {directory}/*.pub {directory}/known_hosts"
    )
    paths = [directory, f"{directory}/id_rsa", f"{directory}/known_hosts"]
    # Exclude directory timestamps: starting the agent creates its environment file.
    before = run(f"stat -c '%a %y %z' {' '.join(paths[1:])}")
    prepare_home(run)
    assert int(mode(run, directory), 8) & 0o777 == 0o700
    assert run(f"stat -c '%a %y %z' {' '.join(paths[1:])}") == before


def test_ssh_permission_repair_does_not_follow_links(ssh_home):
    directory, temporary, run = ssh_home
    run(
        f"mkdir -m 770 {temporary}/external; "
        f"echo keep > {temporary}/external/key; "
        f"chmod 660 {temporary}/external/key; "
        f"ln -s {temporary}/external/key {directory}/linked-key; "
        f"ln -s {temporary}/external {directory}/linked-directory"
    )
    prepare_home(run)
    assert mode(run, f"{temporary}/external") == "770"
    assert mode(run, f"{temporary}/external/key") == "660"
    assert run(f"cat {temporary}/external/key").strip() == "keep"


def test_ssh_unmodifiable_entry_warns_without_aborting(ssh_home, aiidalab_exec):
    directory, _, run = ssh_home
    path = f"{directory}/unmodifiable-key"
    run(f"echo keep > {path}; chmod 660 {path}")
    aiidalab_exec(f"chown 0:0 {path}", user="root")
    output = prepare_home(run)
    assert "Could not restrict SSH file permissions" in output
    assert "HOOK_COMPLETED" in output
    assert mode(run, path) == "660"
    assert mode(run, f"{directory}/id_rsa") == "600"
