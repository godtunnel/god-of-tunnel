#!/bin/bash
#
# God of Tunnel Installer
# TCP/IP L2TPv3 Tunnel Manager for Ubuntu/Debian

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/god-of-tunnel"
BIN_PATH="/usr/local/bin/godtunnel"
SYSTEMD_DIR="/etc/systemd/system"
CONFIG_DIR="/etc/god-of-tunnel"

REPO_URL="https://github.com/godtunnel/god-of-tunnel.git"
REPO_BRANCH="main"

echo -e "${CYAN}"
cat << 'EOF'
   ____           __        _______           _       
  / ___|  ___ ___ \ \      / /_   _|__   ___ | |_ ___ 
  \___ \ / __/ _ \ \ \ /\ / /  | |/ _ \ / _ \| __/ __|
   ___) | (_|  __/  \ V  V /   | | (_) | (_) | |_\__ \
  |____/ \___\___|   \_/\_/    |_|\___/ \___/ \__|___/
EOF

echo -e "${GREEN}God of Tunnel Installer${NC}"
echo -e "${CYAN}TCP/IP L2TPv3 Tunnel Manager for Ubuntu/Debian${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

if ! command -v apt-get &> /dev/null; then
    echo -e "${RED}Error: This installer requires apt-get (Debian/Ubuntu)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/6] Installing system dependencies...${NC}"
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv git socat iproute2

echo -e "${YELLOW}[2/6] Installing kernel modules...${NC}"
KERNEL_VERSION=$(uname -r)
apt-get install -y -qq "linux-modules-extra-$KERNEL_VERSION" 2>/dev/null || true

echo -e "${YELLOW}[3/6] Loading L2TP kernel modules...${NC}"
modprobe l2tp_core 2>/dev/null || true
modprobe l2tp_netlink 2>/dev/null || true
modprobe l2tp_eth 2>/dev/null || true

cat >/etc/modules-load.d/god-of-tunnel.conf <<EOF
l2tp_core
l2tp_netlink
l2tp_eth
EOF

echo -e "${YELLOW}[4/6] Installing God of Tunnel...${NC}"
rm -rf "$INSTALL_DIR"
git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"

echo -e "${YELLOW}[5/6] Installing Python dependencies...${NC}"
apt-get install -y -qq python3-rich python3-yaml 2>/dev/null || pip3 install rich pyyaml

cat >"$BIN_PATH" <<EOF
#!/bin/bash
exec python3 $INSTALL_DIR/vortexl2/main.py "\$@"
EOF

chmod +x "$BIN_PATH"

echo -e "${YELLOW}[6/6] Installing systemd services...${NC}"
cp "$INSTALL_DIR/systemd/vortexl2-tunnel.service" "$SYSTEMD_DIR/" 2>/dev/null || true

mkdir -p "$CONFIG_DIR/tunnels"
chmod 700 "$CONFIG_DIR"

systemctl daemon-reload
systemctl enable vortexl2-tunnel.service 2>/dev/null || true

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} God of Tunnel Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo -e "${CYAN}GitHub:${NC} github.com/godtunnel"
echo -e "${CYAN}Telegram:${NC} @Tw0NoGhTe"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e " 1. Run: ${GREEN}sudo godtunnel${NC}"
echo -e " 2. Create Tunnel (select IRAN or OUTSIDE)"
echo -e " 3. Configure IPs"
echo -e " 4. Add port forwards"
echo ""
