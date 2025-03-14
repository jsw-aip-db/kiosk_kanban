# Mediamatik Kanban Kiosk

A lightweight kiosk application designed to automatically log into and display a Kanban board in fullscreen mode. Perfect for office displays and information radiators.

## Features

- Automated login to web-based Kanban boards
- Runs in fullscreen kiosk mode
- Automatic startup via systemd service
- Secure credential handling with base64 encoding
- Error-resistant installation process
- Python virtual environment isolation

## Prerequisites

- Raspberry Pi (or similar Linux system)
- Python 3.x
- Firefox browser
- Systemd-based Linux distribution
- A user account named 'kiosk'

## Installation

1. Create a user account named 'kiosk' if it doesn't exist:
   ```bash
   sudo useradd -m kiosk
   ```

2. Clone this repository or copy the files to your system

3. Create a `login.properties` file with your credentials:
   ```ini
   [autologin]
   url=https://your-kanban-board-url
   user=your-email@domain.com
   password=base64-encoded-password
   ```
   Note: To generate a base64-encoded password, use:
   ```bash
   echo -n "your-password" | base64
   ```

4. Make the installation script executable:
   ```bash
   chmod +x installx.sh
   ```

5. Run the installation script:
   ```bash
   ./installx.sh
   ```

## Project Structure

```
mediamatik_kanban/
├── install.sh       # Basic installation script
├── installx.sh      # Enhanced installation script with error handling
├── kiosk.service    # Systemd service definition
├── login.properties # Credentials configuration (you need to create this)
├── login.py         # Main automation script
└── requirements.txt # Python dependencies
```

## Configuration

### login.properties

Create this file before installation with the following structure:
```ini
[autologin]
url=https://your-kanban-board-url
user=your-email@domain.com
password=your-base64-encoded-password
```

### Systemd Service

The kiosk service is installed as a user service in:
```
~/.config/systemd/user/kiosk.service
```

## Usage

The service starts automatically after installation and on system boot. To manually control the service:

```bash
# Start the service
systemctl --user start kiosk

# Stop the service
systemctl --user stop kiosk

# Check service status
systemctl --user status kiosk

# View logs
journalctl --user -u kiosk
```

## Troubleshooting

1. If the kiosk fails to start:
   - Check the service status: `systemctl --user status kiosk`
   - View the logs: `journalctl --user -u kiosk`
   - Verify the login.properties file exists and has correct permissions
   - Ensure geckodriver is installed in /usr/local/bin

2. If login fails:
   - Verify your credentials in login.properties
   - Check if the URL is accessible
   - Ensure the base64-encoded password is correct

## Security Considerations

- The password in login.properties is base64 encoded, which is NOT encryption. Ensure the file has appropriate permissions
- The kiosk user should have minimal system privileges
- Consider network-level security measures for the kiosk device

## Dependencies

Main Python packages:
- selenium==4.28.1
- Firefox WebDriver (geckodriver)

For a complete list of dependencies, see `requirements.txt`

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is open source and available under the MIT License.
