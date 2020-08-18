#!/usr/bin/env python
from selenium.webdriver.common.by import By


def test_login(selenium, url):
    selenium.get(url())
    selenium.find_element(By.ID, 'ipython-main-app')
    selenium.find_element(By.ID, 'notebook-container')
    selenium.find_element(By.CLASS_NAME, 'jupyter-widgets-view')
    selenium.get_screenshot_as_file('screenshots/login.png')


def test_tree(selenium, url):
    selenium.get(url('tree/'))
    selenium.find_element(By.ID, 'ipython-main-app')


def test_tree_apps(selenium, url):
    selenium.get(url('tree/apps'))
    selenium.find_element(By.ID, 'ipython-main-app')


def test_apps(selenium, url):
    selenium.get(url('apps/'))
    selenium.find_element(By.ID, 'ipython-main-app')


def test_apps_home(selenium, url):
    selenium.get(url('apps/apps/home/start.ipynb'))
    selenium.find_element(By.ID, 'ipython-main-app')
    selenium.find_element(By.ID, 'notebook-container')
    selenium.find_element(By.CLASS_NAME, 'jupyter-widgets-view')
    selenium.get_screenshot_as_file('screenshots/home.png')
