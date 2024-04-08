"""Tests for all images, which are docker/docker-compose related tests."""

import requests


def test_notebook_service_available(notebook_service):
    response = requests.get(f"{notebook_service}/")
    assert response.status_code == 200


def test_verdi_status(aiidalab_exec, nb_user):
    output = aiidalab_exec("verdi status", user=nb_user).strip()
    assert "Connected to RabbitMQ" in output
    assert "Daemon is running" in output


def test_ssh_agent_is_running(aiidalab_exec, nb_user):
    output = aiidalab_exec("ps aux | grep ssh-agent", user=nb_user).strip()
    assert "ssh-agent" in output

    # also check only one ssh-agent process is running
    assert len(output.splitlines()) == 1


def test_pip_check(aiidalab_exec):
    aiidalab_exec("pip check")
