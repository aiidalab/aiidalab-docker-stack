import pytest
import os
import time
from pathlib import Path
from urllib.parse import urljoin

from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
import selenium.webdriver.support.expected_conditions as EC


@pytest.fixture(scope="function")
def selenium_driver(selenium, notebook_service):
    def _selenium_driver(wait_time=5.0):
        url, token = notebook_service
        url_with_token = urljoin(url, f"apps/apps/quantum-espresso/qe.ipynb?token={token}")
        selenium.get(f"{url_with_token}")
        # By default, let's allow selenium functions to retry for 10s
        # till a given element is loaded, see:
        # https://selenium-python.readthedocs.io/waits.html#implicit-waits
        selenium.implicitly_wait(wait_time)
        window_width = 800
        window_height = 600
        selenium.set_window_size(window_width, window_height)

        selenium.find_element(By.ID, "ipython-main-app")
        selenium.find_element(By.ID, "notebook-container")

        return selenium

    return _selenium_driver


@pytest.fixture
def final_screenshot(request, screenshot_dir, selenium):
    """Take screenshot at the end of the test.
    Screenshot name is generated from the test function name
    by stripping the 'test_' prefix
    """
    screenshot_name = f"{request.function.__name__[5:]}.png"
    screenshot_path = Path.joinpath(screenshot_dir, screenshot_name)
    yield
    selenium.get_screenshot_as_file(screenshot_path)


@pytest.fixture(scope="session")
def screenshot_dir():
    sdir = Path.joinpath(Path.cwd(), "screenshots")
    try:
        os.mkdir(sdir)
    except FileExistsError:
        pass
    return sdir


def test_pw_executable_exist(aiidalab_exec, qe_version, variant):
    """Test that pw.x executable exists in the conda environment"""
    if "qe" not in variant:
        pytest.skip()
    output = (
        aiidalab_exec(f"mamba run -n quantum-espresso-{qe_version} which pw.x")
        .decode()
        .strip()
    )

    assert output == f"/home/jovyan/.conda/envs/quantum-espresso-{qe_version}/bin/pw.x"

def test_qe_app_select_silicon_and_confirm(
    selenium_driver,
    screenshot_dir,
    final_screenshot,
):
    driver = selenium_driver(wait_time=60.0)
    driver.set_window_size(1920, 1485)

    element = WebDriverWait(driver, 60).until(
        EC.presence_of_element_located((By.XPATH, "//*[text()='From Examples']"))
    )
    element.click()

    driver.find_element(By.XPATH, "//option[@value='Diamond']").click()
    time.sleep(10)

    driver.get_screenshot_as_file(
        str(Path.joinpath(screenshot_dir, "qe-app-select-diamond-selected.png"))
    )

    element = WebDriverWait(driver, 60).until(
        EC.element_to_be_clickable((By.XPATH, "//button[text()='Confirm']"))
    )
    element.click()

    # Test that we have indeed proceeded to the next step
    driver.find_element(By.XPATH, "//span[contains(.,'✓ Step 1')]")
