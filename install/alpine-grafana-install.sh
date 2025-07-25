#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/fmcglinn/ProxmoxVE-HelperScripts-local/raw/main/LICENSE
# Source: https://grafana.com/

source "$(dirname "$0")/../$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Grafana"
$STD apk add grafana
$STD sed -i '/http_addr/s/127.0.0.1/0.0.0.0/g' /etc/conf.d/grafana
$STD rc-service grafana start
$STD rc-update add grafana default
msg_ok "Installed Grafana"

motd_ssh
customize
