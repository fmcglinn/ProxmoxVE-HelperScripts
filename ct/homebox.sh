#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://homebox.software/en/

APP="HomeBox"
var_tags="${var_tags:-inventory;household}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors
function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/homebox ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  if [[ -x /opt/homebox ]]; then
    sed -i 's|/opt\b|/opt/homebox|g' /etc/systemd/system/homebox.service
    sed -i 's|^ExecStart=/opt/homebox$|ExecStart=/opt/homebox/homebox|' /etc/systemd/system/homebox.service
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/sysadminsmedia/homebox/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.homebox 2>/dev/null)" ]] || [[ ! -f ~/.homebox ]]; then
    msg_info "Stopping ${APP}"
    systemctl stop homebox
    msg_ok "${APP} Stopped"

    fetch_and_deploy_gh_release "homebox" "sysadminsmedia/homebox" "prebuild" "latest" "/opt/homebox" "homebox_Linux_x86_64.tar.gz"
    chmod +x /opt/homebox/homebox
    [ -f /opt/.env ] && mv /opt/.env /opt/homebox/.env

    msg_info "Starting ${APP}"
    systemctl start homebox
    msg_ok "Started ${APP}"

    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7745${CL}"
