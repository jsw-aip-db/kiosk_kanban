import os
import configparser
import base64
import logging
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.firefox.service import Service
import platform
import time

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def load_config():
    """
    Load configuration from login.properties file.
    
    Returns:
        configparser.ConfigParser: Configuration object.
    """
    config = configparser.ConfigParser(interpolation=None)
    config_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'login.properties')
    if not os.path.exists(config_file_path):
        logging.error("Configuration file not found: %s", config_file_path)
        raise FileNotFoundError("Configuration file not found")
    config.read(config_file_path)
    return config


def setup_browser():
    """
    Set up Firefox browser with kiosk mode and fullscreen preference.
    
    Returns:
        webdriver.Firefox: Firefox browser object.
    """
    options = Options()
    options.add_argument("--kiosk")
    options.set_preference("browser.fullscreen.autohide", True)
    if platform.machine() == 'aarch64':
        service = Service(executable_path='/usr/local/bin/geckodriver')
        browser = webdriver.Firefox(options=options, service=service)
    else:
        browser = webdriver.Firefox(options=options)
    return browser


def login_to_kanban(browser, config):
    """
    Perform login to Kanban using the provided browser and configuration.
    
    Args:
        browser (webdriver.Firefox): Firefox browser object.
        config (configparser.ConfigParser): Configuration object.
    """
    try:
        url = config['autologin']['url']
        user = config['autologin']['user']
        password = base64.b64decode(config['autologin']['password']).decode('utf-8')

        if not url or not user or not password:
            logging.error("Invalid configuration values.")
            raise ValueError("URL, user, and password must be provided.")

        logging.info("Navigating to %s", url)
        browser.get(url)

        # Wait for and enter email
        WebDriverWait(browser, 10).until(EC.element_to_be_clickable((By.ID, "i0116"))).send_keys(user)
        WebDriverWait(browser, 10).until(EC.element_to_be_clickable((By.ID, "idSIButton9"))).click()

        # Wait for and enter password
        WebDriverWait(browser, 10).until(EC.element_to_be_clickable((By.ID, "i0118"))).send_keys(password)
        WebDriverWait(browser, 10).until(EC.element_to_be_clickable((By.ID, "idSIButton9"))).click()
        WebDriverWait(browser, 10).until(EC.element_to_be_clickable((By.ID, "idSIButton9"))).click()

        logging.info("Login successful.")
        while True:
            browser.refresh()
            logging.info("Page refreshed.")
            time.sleep(60)
    except Exception as e:
        logging.error("An error occurred during login: %s", e)
    finally:
        logging.info("Login process completed.")


def main():
    """
    Main entry point of the script.
    """
    try:
        config = load_config()
        browser = setup_browser()
        login_to_kanban(browser, config)
    except Exception as e:
        logging.error("Script terminated: %s", e)


if __name__ == '__main__':
    main()
