#!/bin/bash

clear

echo "=========================================="
echo "      HYSTERIA2 AUTO INSTALLER"
echo "=========================================="

# ROOT CHECK
if [[ $EUID -ne 0 ]]; then
   echo "Run as root"
   exit 1
fi

# INSTALL PACKAGES
apt update -y
apt install -y curl wget sudo openssl qrencode ufw

# INSTALL HYSTERIA2
bash <(curl -fsSL https://get.hy2.sh/)

# SERVER INFO
IP=$(curl -4 -s ip.sb)
PORT=443
PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

# CREATE FOLDER
mkdir -p /etc/hysteria

# GENERATE SSL
openssl req -x509 -nodes -newkey rsa:2048 \
-keyout /etc/hysteria/server.key \
-out /etc/hysteria/server.crt \
-days 3650 \
-subj "/CN=bing.com"

# FIX PERMISSION
chmod 644 /etc/hysteria/server.key
chmod 644 /etc/hysteria/server.crt

# CREATE CONFIG
cat > /etc/hysteria/config.yaml <<EOF
listen: :$PORT

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $PASS

masquerade:
  type: proxy
  proxy:
    url: https://bing.com

ignoreClientBandwidth: true

quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864

udpIdleTimeout: 60s
EOF

# DETECT HYSTERIA PATH
HY2=$(which hysteria)

# CREATE SYSTEMD SERVICE
cat > /etc/systemd/system/hysteria-server.service <<EOF
[Unit]
Description=Hysteria2 Server
After=network.target

[Service]
Type=simple
ExecStart=$HY2 server -c /etc/hysteria/config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# FIREWALL
ufw allow $PORT/tcp
ufw allow $PORT/udp
ufw --force enable

# ENABLE BBR
grep -q "tcp_congestion_control=bbr" /etc/sysctl.conf || cat >> /etc/sysctl.conf <<EOF

net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=2500000
net.core.wmem_max=2500000
EOF

sysctl -p

# START SERVICE
systemctl daemon-reload
systemctl enable hysteria-server
systemctl restart hysteria-server

sleep 3

STATUS=$(systemctl is-active hysteria-server)

clear

echo "=========================================="
echo "          HYSTERIA2 STATUS"
echo "=========================================="
echo ""

if [ "$STATUS" = "active" ]; then

URI="hysteria2://$PASS@$IP:$PORT?sni=bing.com&insecure=1#HY2"

echo "STATUS : RUNNING"
echo "IP     : $IP"
echo "PORT   : $PORT"
echo "PASS   : $PASS"
echo ""

echo "============== URI ======================"
echo ""
echo "$URI"
echo ""

echo "============== QR ======================="
echo ""
qrencode -t ANSIUTF8 "$URI"
echo ""

echo "============== CONFIG ==================="
echo ""

cat <<EOL
server: $IP:$PORT

auth: $PASS

tls:
  sni: bing.com
  insecure: true

transport:
  type: udp

socks5:
  listen: 127.0.0.1:1080

http:
  listen: 127.0.0.1:8989
EOL

echo ""
echo "=========================================="
echo " SOCKS5 : 127.0.0.1:1080"
echo " HTTP   : 127.0.0.1:8989"
echo "=========================================="

else

echo "FAILED TO START"
echo ""

journalctl -u hysteria-server -n 50 --no-pager

fi
