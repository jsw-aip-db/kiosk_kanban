#!/bin/bash

# This script installs the kanban kiosk on a rasperry pi. 
#
# Usage: 
# 1. create login.properties with url and credentials
# 2. chmod +x installx.sh 
# 3. run ./installx.sh

set -e  # Exit on error

# Check if script is run as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run as root. Use a regular user account."
    exit 1
fi

# Check if login.properties exists
if [ ! -f "login.properties" ]; then
    echo "Error: login.properties not found. Please create it first."
    exit 1
fi

USER="kiosk"

# Check if user exists
if ! id "$USER" &>/dev/null; then
    echo "Error: User $USER does not exist. Please create the user first."
    exit 1
fi

# define service
SERVICE=$(cat << EOF
[Unit]
Description=Kanban Kiosk
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/home/$USER/autologin/.venv/bin/python /home/$USER/autologin/login.py
Restart=always
ExitType=cgroup

[Install]
WantedBy=default.target
EOF
)

# autologin script
AUTOLOGIN=$(cat << EOF
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
EOF
)

# python requirements
REQUIREMENTS=$(cat << EOF
asttokens==3.0.0
attrs==25.1.0
backcall==0.2.0
beautifulsoup4==4.13.1
bleach==6.2.0
certifi==2025.1.31
charset-normalizer==3.4.1
decorator==5.1.1
defusedxml==0.7.1
docopt==0.6.2
exceptiongroup==1.2.2
executing==2.2.0
fastjsonschema==2.21.1
h11==0.14.0
idna==3.10
ipython==8.12.3
jedi==0.19.2
Jinja2==3.1.5
jsonschema==4.23.0
jsonschema-specifications==2024.10.1
jupyter_client==8.6.3
jupyter_core==5.7.2
jupyterlab_pygments==0.3.0
MarkupSafe==3.0.2
matplotlib-inline==0.1.7
mistune==3.1.1
nbclient==0.10.2
nbconvert==7.16.6
nbformat==5.10.4
outcome==1.3.0.post0
packaging==24.2
pandocfilters==1.5.1
parso==0.8.4
pexpect==4.9.0
pickleshare==0.7.5
platformdirs==4.3.6
prompt_toolkit==3.0.50
ptyprocess==0.7.0
pure_eval==0.2.3
Pygments==2.19.1
PySocks==1.7.1
python-dateutil==2.9.0.post0
pyzmq==26.2.1
referencing==0.36.2
requests==2.32.3
rpds-py==0.22.3
selenium==4.28.1
six==1.17.0
sniffio==1.3.1
sortedcontainers==2.4.0
soupsieve==2.6
stack-data==0.6.3
tinycss2==1.4.0
tornado==6.4.2
traitlets==5.14.3
trio==0.28.0
trio-websocket==0.11.1
typing_extensions==4.12.2
urllib3==2.3.0
wcwidth==0.2.13
webencodings==0.5.1
websocket-client==1.8.0
wsproto==1.2.0
yarg==0.1.9
EOF
)

# install geckodriver
if [ ! -f /usr/local/bin/geckodriver ]; then
    echo "Installing geckodriver..."
    if ! wget https://github.com/mozilla/geckodriver/releases/download/v0.36.0/geckodriver-v0.36.0-linux-aarch64.tar.gz; then
        echo "Error: Failed to download geckodriver"
        exit 1
    fi
    tar -xvf geckodriver-v0.36.0-linux-aarch64.tar.gz || { echo "Error: Failed to extract geckodriver"; exit 1; }
    sudo mv geckodriver /usr/local/bin || { echo "Error: Failed to move geckodriver to /usr/local/bin"; exit 1; }
    rm geckodriver-v0.36.0-linux-aarch64.tar.gz
    echo "Geckodriver installed successfully"
fi

# setup autologin script
echo "Setting up autologin script..."
mkdir -p /home/$USER/autologin || { echo "Error: Failed to create autologin directory"; exit 1; }
cp login.properties /home/$USER/autologin/login.properties || { echo "Error: Failed to copy login.properties"; exit 1; }
echo "$AUTOLOGIN" > /home/$USER/autologin/login.py || { echo "Error: Failed to create login.py"; exit 1; }
echo "$REQUIREMENTS" > /home/$USER/autologin/requirements.txt || { echo "Error: Failed to create requirements.txt"; exit 1; }

# Create and activate virtual environment
echo "Setting up Python virtual environment..."
if ! python -m venv /home/$USER/autologin/.venv; then
    echo "Error: Failed to create virtual environment"
    exit 1
fi

if ! /home/$USER/autologin/.venv/bin/python -m pip install -r /home/$USER/autologin/requirements.txt; then
    echo "Error: Failed to install Python requirements"
    exit 1
fi

# setup systemd
echo "Setting up systemd service..."
mkdir -p /home/$USER/.config/systemd/user || { echo "Error: Failed to create systemd user directory"; exit 1; }
echo "$SERVICE" > /home/$USER/.config/systemd/user/kiosk.service || { echo "Error: Failed to create service file"; exit 1; }

# Fix permissions
chown -R $USER:$USER /home/$USER/autologin || { echo "Error: Failed to set permissions"; exit 1; }

# Enable and start service
if ! systemctl --user enable kiosk; then
    echo "Error: Failed to enable kiosk service"
    exit 1
fi

if ! systemctl --user start kiosk; then
    echo "Error: Failed to start kiosk service"
    exit 1
fi

echo "Installation completed successfully!"