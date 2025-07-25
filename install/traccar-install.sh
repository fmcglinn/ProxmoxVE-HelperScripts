#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/fmcglinn/ProxmoxVE-HelperScripts-local/raw/main/LICENSE
# Source: https://www.traccar.org/

source "$(dirname "$0")/../$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

RELEASE=$(curl -fsSL https://api.github.com/repos/traccar/traccar/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
msg_info "Installing Traccar v${RELEASE}"
curl -fsSL "https://github.com/traccar/traccar/releases/download/v${RELEASE}/traccar-linux-64-${RELEASE}.zip" -o "traccar-linux-64-${RELEASE}.zip"
$STD unzip traccar-linux-64-${RELEASE}.zip
$STD ./traccar.run
systemctl enable -q --now traccar
rm -rf README.txt traccar-linux-64-${RELEASE}.zip traccar.run
msg_ok "Installed Traccar v${RELEASE}"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
