#!/bin/bash
# Godtunnel Installer v1.0
# TCP/IP Tunnel Manager with Interactive Panel

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DIR="/opt/godtunnel"
CONFIG_DIR="/etc/godtunnel"
BIN_PATH="/usr/local/bin/godtunnel"

# ===============================
# Logo
# ===============================
clear
echo -e "${YELLOW}"
cat << 'EOF'
   ____       _      _______             _       
  / ___|  ___| |_   |__   __|__ _  ___ | |_ ___ 
  \___ \ / _ \ __|     | |/ _ \ |/ _ \| __/ __|
   ___) |  __/ |_      | |  __/ | (_) | |_\__ \
  |____/ \___|\__|     |_|\___|_|\___/ \__|___/
EOF
echo -e "${GREEN}Godtunnel Installer${NC}"
echo -e "${CYAN}TCP/IP Tunnel Manager${NC}\n"

# ===============================
# Check root
# ===============================
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run as root!${NC}"
    exit 1
fi

# ===============================
# Dependencies
# ===============================
echo -e "${YELLOW}[1/5] Installing dependencies...${NC}"
apt-get update -qq
apt-get install -y socat iproute2 systemd curl >/dev/null

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR/tunnels"

# ===============================
# Interactive Panel
# ===============================
echo -e "${CYAN}Select server role:${NC}"
echo "1️⃣  IRAN Server"
echo "2️⃣  OUTSIDE Server"
read -p "Enter choice [1/2]: " ROLE
ROLE=${ROLE:-1}
if [[ "$ROLE" == "1" ]]; then SERVER_ROLE="IRAN"; else SERVER_ROLE="OUTSIDE"; fi

read -p "Enter LOCAL IP (default 10.10.10.1): " LOCAL_IP
LOCAL_IP=${LOCAL_IP:-10.10.10.1}

read -p "Enter REMOTE PUBLIC IP: " REMOTE_IP

read -p "Enter TCP ports to tunnel (comma-separated, default 80,443,8080): " PORTS
PORTS=${PORTS:-80,443,8080}

echo -e "\n🚀 ${GREEN}${SERVER_ROLE} CONFIGURATION${NC}"
echo "Local IP: $LOCAL_IP"
echo "Remote IP: $REMOTE_IP"
echo "Ports: $PORTS"
echo ""

# ===============================
# Create systemd services for each port
# ===============================
for PORT in $(echo $PORTS | tr ',' ' '); do
SERVICE_NAME="godtunnel-$PORT.service"
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

# Dummy listener check
ss -tuln | grep -q ":$PORT" || {
  DUMMY_SERVICE="dummy-$PORT.service"
  cat >"$CONFIG_DIR/$DUMMY_SERVICE" <<EOF2
[Unit]
Description=Dummy Listener $PORT
After=network.target
[Service]
ExecStart=/usr/bin/socat TCP4-LISTEN:$PORT,fork TCP4:127.0.0.1:$PORT
Restart=always
[Install]
WantedBy=multi-user.target
EOF2
  cp "$CONFIG_DIR/$DUMMY_SERVICE" /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable "$DUMMY_SERVICE"
  systemctl start "$DUMMY_SERVICE"
  echo -e "${YELLOW}⚠️ Port $PORT already in use, dummy listener created${NC}"
}

echo -e "${GREEN}✅ Port $PORT tunnel created${NC}"
done

# ===============================
# Create executable panel
# ===============================
cat >"$BIN_PATH" <<'EOF'
#!/bin/bash
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${YELLOW}Godtunnel Panel${NC}"
echo -e "${CYAN}Telegram: @Tw0NoGhTe${NC}"
echo -e "${CYAN}GitHub: github.com/godtunnel${NC}"
echo ""
systemctl list-units --type=service | grep godtunnel-
EOF
chmod +x "$BIN_PATH"

# ===============================
# Finished
# ===============================
echo -e "\n${GREEN}======================================${NC}"
echo -e "${GREEN} Godtunnel Installation Complete! ${NC}"
echo -e "${GREEN}======================================${NC}"
echo -e "${CYAN}Run 'sudo godtunnel' to view panel and tunnels${NC}\n"
