from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options

import configparser
import base64

config = configparser.ConfigParser(interpolation=None)

# Read the properties file
config.read('login.properties')

options = Options()
#options.add_argument("--kiosk") 
# options.set_preference("browser.fullscreen.autohide", True)

EMAILFIELD = (By.ID, "i0116")
PASSWORDFIELD = (By.ID, "i0118")
NEXTBUTTON = (By.ID, "idSIButton9")

browser = webdriver.Firefox(options=options)
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