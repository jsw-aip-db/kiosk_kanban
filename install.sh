#!/bin/bash

CURSOR_PATH="/usr/share/icons/Adwaita/cursors/left_ptr"
USER="kiosk"
KEYBOARD="ch"

AUTH=$(cat << EOF
auth           required        pam_unix.so nullok
account        required        pam_unix.so
session        required        pam_unix.so
session        required        pam_systemd.so
EOF

)

SERV=$(cat << EOF
[Unit]
Description=Cage Wayland compositor on %I
After=systemd-user-sessions.service
Before=graphical.target
ConditionPathExists=/dev/tty0
Wants=dbus.socket systemd-logind.service
After=dbus.socket systemd-logind.service
Conflicts=getty@%i.service
After=getty@%i.service

[Service]
Type=simple
ExecStart=cage -s -- python ~/autologin/login.py
Environment="XKB_DEFAULT_LAYOUT=$KEYBOARD"
Restart=always
User=$USER
UtmpIdentifier=%I
UtmpMode=user
TTYPath=/dev/%I
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty-fail

PAMName=cage

[Install]
WantedBy=graphical.target
DefaultInstance=tty7
EOF

)

yes | apt update
yes | apt upgrade
yes | apt install firefox-esr cage xwayland

cp login.properties /home/$USER/autologin/login.properties
cp login.py /home/$USER/autologin/login.py
cp requirements.txt /home/$USER/autologin/requirements.py

python -m venv /home/$USER/autologin/.venv
source /home/$USER/autologin/.venv/bin/activate
python -m pip install -r /home/$USER/autologin/requirements.txt


echo "$SERV" > /etc/systemd/system/cage@.service
echo "$AUTH" > /etc/pam.d/cage
systemctl enable cage@tty1.service
systemctl set-default graphical.target

mv "${CURSOR_PATH}" "${CURSOR_PATH}.bak"

systemctl reboot
