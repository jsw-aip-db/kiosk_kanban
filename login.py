from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service

import os
import configparser
import base64

config = configparser.ConfigParser(interpolation=None)

# Get the directory of the current script
script_dir = os.path.dirname(os.path.abspath(__file__))

# Define the path to the config file
config_file_path = os.path.join(script_dir, 'login.properties')

# Read the properties file
config.read(config_file_path)

options = Options()
options.add_argument("--kiosk") 
options.set_preference("browser.fullscreen.autohide", True)

service = Service(executable_path='/usr/local/bin/geckodriver')

EMAILFIELD = (By.ID, "i0116")
PASSWORDFIELD = (By.ID, "i0118")
NEXTBUTTON = (By.ID, "idSIButton9")

browser = webdriver.Firefox(options=options, service=service)
browser.get(config['autologin']['url'])

# wait for email field and enter email
WebDriverWait(browser, 2000).until(EC.element_to_be_clickable(EMAILFIELD)).send_keys(config['autologin']['user'])

# Click Next
WebDriverWait(browser, 10).until(EC.element_to_be_clickable(NEXTBUTTON)).click()

# wait for password field and enter password
password = base64.b64decode(config['autologin']['password'])

WebDriverWait(browser, 10).until(EC.element_to_be_clickable(PASSWORDFIELD)).send_keys(password.decode('utf-8'))

# Click Login - same id?
WebDriverWait(browser, 10).until(EC.element_to_be_clickable(NEXTBUTTON)).click()
WebDriverWait(browser, 10).until(EC.element_to_be_clickable(NEXTBUTTON)).click()
