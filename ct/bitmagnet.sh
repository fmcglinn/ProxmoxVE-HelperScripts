#!/usr/bin/env bash
source "$(dirname "$0")/../misc/build.func"
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/fmcglinn/ProxmoxVE-HelperScripts-local/raw/main/LICENSE
# Source: https://github.com/bitmagnet/bitmagnet

APP="Bitmagnet"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
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
  if [[ ! -d /opt/bitmagnet ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/bitmagnet-io/bitmagnet/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Stopping Service"
    systemctl stop bitmagnet-web
    msg_ok "Stopped Service"

    msg_info "Backing up database"
    rm -f /tmp/backup.sql
    $STD sudo -u postgres pg_dump \
      --column-inserts \
      --data-only \
      --on-conflict-do-nothing \
      --rows-per-insert=1000 \
      --table=metadata_sources \
      --table=content \
      --table=content_attributes \
      --table=content_collections \
      --table=content_collections_content \
      --table=torrent_sources \
      --table=torrents \
      --table=torrent_files \
      --table=torrent_hints \
      --table=torrent_contents \
      --table=torrent_tags \
      --table=torrents_torrent_sources \
      --table=key_values \
      bitmagnet \
      >/tmp/backup.sql
    mv /tmp/backup.sql /opt/
    msg_ok "Database backed up"

    msg_info "Updating ${APP} to v${RELEASE}"
    [ -f /opt/bitmagnet/.env ] && cp /opt/bitmagnet/.env /opt/
    [ -f /opt/bitmagnet/config.yml ] && cp /opt/bitmagnet/config.yml /opt/
    rm -rf /opt/bitmagnet/*
    temp_file=$(mktemp)
    curl -fsSL "https://github.com/bitmagnet-io/bitmagnet/archive/refs/tags/v${RELEASE}.tar.gz" -o "$temp_file"
    tar zxf "$temp_file" --strip-components=1 -C /opt/bitmagnet
    cd /opt/bitmagnet
    VREL=v$RELEASE
    $STD go build -ldflags "-s -w -X github.com/bitmagnet-io/bitmagnet/internal/version.GitTag=$VREL"
    chmod +x bitmagnet
    [ -f "/opt/.env" ] && cp "/opt/.env" /opt/bitmagnet/
    [ -f "/opt/config.yml" ] && cp "/opt/config.yml" /opt/bitmagnet/
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated $APP to v${RELEASE}"

    msg_info "Starting Service"
    systemctl start bitmagnet-web
    msg_ok "Started Service"

    msg_info "Cleaning up"
    rm -f "$temp_file"
    msg_ok "Cleaned"
    msg_ok "Updated Successfully"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3333${CL}"
