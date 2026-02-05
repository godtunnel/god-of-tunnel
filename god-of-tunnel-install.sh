#!/bin/bash
# Godtunnel Installer v1.0
# TCP/IP Tunnel Manager with Shiny TUI

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/godtunnel"
BIN_PATH="/usr/local/bin/godtunnel"
CONFIG_DIR="/etc/godtunnel"

# ===============================
# LOGO
# ===============================
echo -e "${YELLOW}"
cat << 'EOF'
   ____       _      _______             _       
  / ___|  ___| |_   |__   __|__ _  ___ | |_ ___ 
  \___ \ / _ \ __|     | |/ _ \ |/ _ \| __/ __|
   ___) |  __/ |_      | |  __/ | (_) | |_\__ \
  |____/ \___|\__|     |_|\___|_|\___/ \__|___/
                                              
EOF
echo -e "${GREEN}Godtunnel Installer${NC}"
echo -e "${CYAN}TCP/IP Tunnel Manager${NC}"
echo ""

# ===============================
# CHECK ROOT
# ===============================
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root!${NC}"
    exit 1
fi

# ===============================
# INSTALL DEPENDENCIES
# ===============================
echo -e "${YELLOW}[1/5] Installing system dependencies...${NC}"
apt-get update -qq
apt-get install -y python3 python3-pip python3-venv git socat iproute2 python3-rich

mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR/tunnels"
chmod 700 "$CONFIG_DIR"

# ===============================
# DOWNLOAD MAIN SCRIPT
# ===============================
echo -e "${YELLOW}[2/5] Downloading Godtunnel scripts...${NC}"
curl -fsSL https://raw.githubusercontent.com/iliya-Developer/VortexL2/main/install.sh -o "$INSTALL_DIR/main.py"

# ===============================
# CREATE EXECUTABLE
# ===============================
cat >"$BIN_PATH" <<'EOF'
#!/bin/bash
python3 /opt/godtunnel/main.py "$@"
EOF
chmod +x "$BIN_PATH"

# ===============================
# INTERACTIVE PANEL
# ===============================
function draw_panel {
    clear
    echo -e "${YELLOW}🟡 Godtunnel - TCP/IP Tunnel Manager${NC}"
    echo ""
    echo "1️⃣  IRAN Server"
    echo "2️⃣  OUTSIDE Server"
    echo ""
    read -p "Select server role (1/2): " ROLE
    if [[ "$ROLE" == "1" ]]; then
        SERVER_ROLE="IRAN"
    else
        SERVER_ROLE="OUTSIDE"
    fi

    read -p "Enter local IP for this server (default 10.10.10.1): " LOCAL_IP
    LOCAL_IP=${LOCAL_IP:-10.10.10.1}

    read -p "Enter remote public IP (example 212.95.35.229): " REMOTE_IP

    read -p "Enter ports to tunnel (comma-separated, default 80,443,8080): " PORTS
    PORTS=${PORTS:-80,443,8080}

    echo ""
    echo -e "🚀 ${GREEN}${SERVER_ROLE} CONFIGURATION${NC}"
    echo "Local IP: $LOCAL_IP"
    echo "Remote IP: $REMOTE_IP"
    echo "Ports: $PORTS"
    echo ""
}

# ===============================
# SHOW PANEL
# ===============================
draw_panel

# ===============================
# CREATE SYSTEMD SERVICES FOR EACH PORT
# ===============================
for PORT in $(echo $PORTS | tr ',' ' '); do
    SERVICE_NAME="tunnel-$PORT.service"
    cat >"$CONFIG_DIR/$SERVICE_NAME" <<EOF
[Unit]
Description=Godtunnel Plain TCP Tunnel Port $PORT
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP4-LISTEN:$PORT,fork TCP4:$REMOTE_IP:$PORT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    cp "$CONFIG_DIR/$SERVICE_NAME" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
done

# ===============================
# FINISHED
# ===============================
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} Godtunnel Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "${CYAN}Telegram: @Tw0NoGhTe${NC}"
echo -e "${CYAN}GitHub: github.com/godtunnel${NC}"
echo -e "${CYAN}Run 'sudo godtunnel' to manage tunnels${NC}"
