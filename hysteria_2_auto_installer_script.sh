#!/bin/bash

clear

echo "======================================="
echo "      HYSTERIA2 AUTO INSTALLER"
echo "======================================="

apt update -y
apt install -y curl wget sudo ufw openssl qrencode

# INSTALL HYSTERIA2
bash <(curl -fsSL https://get.hy2.sh/)

# SERVER INFO
IP=$(curl -4 -s ip.sb)
PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

mkdir -p /etc/hysteria

# SSL CERT
openssl req -x509 -nodes -newkey rsa:2048 \
-keyout /etc/hysteria/server.key \
-out /etc/hysteria/server.crt \
-days 3650 \
-subj "/CN=bing.com"

# HYSTERIA2 CONFIG
cat > /etc/hysteria/config.yaml <<EOF
listen: :443

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $PASS

masquerade:
  type: proxy
  proxy:
    url: https://www.microsoft.com

ignoreClientBandwidth: true

quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864

udpIdleTimeout: 60s
EOF

# FIREWALL
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

# BBR OPTIMIZATION
cat >> /etc/sysctl.conf <<EOF

net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=2500000
net.core.wmem_max=2500000
EOF

sysctl -p

# RESTART SERVICE
systemctl daemon-reload
systemctl enable hysteria-server
systemctl restart hysteria-server

sleep 3

STATUS=$(systemctl is-active hysteria-server)

clear

if [ "$STATUS" = "active" ]; then

echo "======================================="
echo "       HYSTERIA2 INSTALLED"
echo "======================================="
echo ""
echo "STATUS : RUNNING"
echo "SERVER : $IP"
echo "PORT   : 443"
echo "PASS   : $PASS"
echo ""

echo "============== CLIENT CONFIG =========="
echo ""

cat <<EOL
server: $IP:443

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

fastOpen: true
lazy: true
EOL

echo ""
echo "============== URI ===================="
echo ""

URI="hysteria2://$PASS@$IP:443?sni=bing.com&insecure=1#HY2"

echo "$URI"

echo ""
echo "============== QR ====================="
echo ""

qrencode -t ANSIUTF8 "$URI"

echo ""
echo "======================================="
echo "SOCKS5 : 127.0.0.1:1080"
echo "HTTP   : 127.0.0.1:8989"
echo "======================================="

else

echo "======================================="
echo " HYSTERIA2 FAILED TO START"
echo "======================================="

journalctl -u hysteria-server -n 50 --no-pager

fi
