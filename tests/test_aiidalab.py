import requests


def test_notebook_service_available(notebook_service):
    response = requests.get(f"{notebook_service}/")
    assert response.status_code == 200


def test_pip_check(aiidalab_exec):
    aiidalab_exec("pip check")


def test_aiidalab_available(aiidalab_exec, nb_user):
    output = aiidalab_exec("aiidalab --version", user=nb_user).decode().strip().lower()
    assert "aiidalab" in output


def test_create_conda_environment(aiidalab_exec, nb_user):
    output = aiidalab_exec("conda create -y -n tmp", user=nb_user).decode().strip()
    assert "conda activate tmp" in output


def test_verdi_status(aiidalab_exec, nb_user):
    output = aiidalab_exec("verdi status", user=nb_user).decode().strip()
    assert "Connected to RabbitMQ" in output
    assert "Daemon is running" in output
