#!/usr/bin/env bash
#=====================================================================
# MindsDB – Proxmox VE Helper Script
#=====================================================================
# Copyright (c) 2021‑2025 tteck
# Author: havardthom (adapted for MindsDB)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mindsdb/mindsdb
#=====================================================================

source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

APP="MindsDB"
# Default resources – feel free to change them when the wizard appears
var_tags="${var_tags:-ml;ai}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

# --------------------------------------------------------------------
# Update function – runs when the script is called *inside* the container
# --------------------------------------------------------------------
function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d /opt/mindsdb ]]; then
        msg_error "No ${APP} installation found!"
        exit 1
    fi

    msg_info "Updating ${APP}"
    cd /opt/mindsdb
    source venv/bin/activate
    $STD pip install --upgrade mindsdb
    deactivate

    systemctl restart mindsdb.service
    msg_ok "${APP} updated and service restarted"
    exit
}

# --------------------------------------------------------------------
# The standard Proxmox flow
#   1️⃣ start          – builds the LXC container (or offers the update menu)
#   2️⃣ build_container – creates the container with the chosen resources
#   3️⃣ description    – writes a nice description in the LXC UI
# --------------------------------------------------------------------
start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it on port 47334 (MindsDB SQL API)${CL}"
