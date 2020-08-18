#!/usr/bin/env python
from selenium.webdriver.common.by import By


def test_uninstall_install_widgets_base(selenium, url):
    selenium.get(url("apps/apps/home/single_app.ipynb?app=aiidalab-widgets-base"))
    selenium.set_window_size(1575, 907)
    selenium.find_element(By.XPATH, "//button[contains(.,\'Uninstall\')]").click()
    selenium.get_screenshot_as_file(f'screenshots/manage-app-aiidalab-widgets-base-uninstalled.png')
    selenium.find_element(By.XPATH, "//button[contains(.,\'Install\')]").click()
    selenium.get_screenshot_as_file(f'screenshots/manage-app-aiidalab-widgets-base-installed.png')
    selenium.find_element(By.XPATH, "//div[@id=\'notebook-container\']/div[5]/div[2]/div[2]/div/div[3]/div/div[2]/div[2]/select").click()
    selenium.find_element(By.CSS_SELECTOR, ".widget-dropdown > .widget-label").click()
    selenium.get_screenshot_as_file(f'screenshots/manage-app-aiidalab-widgets-base.png')
