#!/usr/bin/env bash
#=====================================================================
# MindsDB – install script executed inside the LXC container
#=====================================================================
# Copyright (c) 2021‑2025 tteck
# Author: havardthom (adapted for MindsDB)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/mindsdb/mindsdb
#=====================================================================

# All helper functions (color, msg_*, $STD, etc.) are loaded here
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors

# --------------------------------------------------------------------
# 1️⃣ Basic container preparation
# --------------------------------------------------------------------
setting_up_container
network_check
update_os

# --------------------------------------------------------------------
# 2️⃣ Install system packages needed by MindsDB
# --------------------------------------------------------------------
msg_info "Installing base dependencies"
$STD apt-get install -y \
    git \
    curl \
    python3 \
    python3-venv \
    python3-pip \
    build-essential \
    libssl-dev \
    libffi-dev
msg_ok "Base dependencies installed"

# --------------------------------------------------------------------
# 3️⃣ Create a virtual‑env and install MindsDB via pip
# --------------------------------------------------------------------
msg_info "Setting up MindsDB environment"
INSTALL_DIR="/opt/mindsdb"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Create a clean venv
python3 -m venv venv
source venv/bin/activate

# Upgrade pip & install MindsDB
$STD pip install --upgrade pip setuptools wheel
$STD pip install mindsdb
deactivate
msg_ok "MindsDB installed into $INSTALL_DIR/venv"

# --------------------------------------------------------------------
# 4️⃣ Systemd service – makes MindsDB start automatically
# --------------------------------------------------------------------
msg_info "Creating Systemd service"
cat > /etc/systemd/system/mindsdb.service <<'EOF'
[Unit]
Description=MindsDB Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/mindsdb
ExecStart=/opt/mindsdb/venv/bin/mindsdb
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable -q --now mindsdb.service
msg_ok "Systemd service created and started"

# --------------------------------------------------------------------
# 5️⃣ Finish up – MOTD, cleanup, customisation
# --------------------------------------------------------------------
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned up"

