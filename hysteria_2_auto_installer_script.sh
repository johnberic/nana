#!/bin/bash

apt update -y && apt install -y curl wget sudo ufw openssl qrencode

bash <(curl -fsSL https://get.hy2.sh/)

IP=$(curl -4 -s ip.sb)
PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

mkdir -p /etc/hysteria

openssl req -x509 -nodes -newkey rsa:2048 \
-keyout /etc/hysteria/server.key \
-out /etc/hysteria/server.crt \
-days 3650 \
-subj "/CN=bing.com"

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

bandwidth:
  up: 200 mbps
  down: 1000 mbps

ignoreClientBandwidth: false

udpIdleTimeout: 60s
EOF

ufw allow 443/udp
ufw allow 443/tcp

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
echo "net.core.rmem_max=2500000" >> /etc/sysctl.conf
echo "net.core.wmem_max=2500000" >> /etc/sysctl.conf

sysctl -p

systemctl enable hysteria-server
systemctl restart hysteria-server

clear

echo "======================================="
echo "         HYSTERIA2 INSTALLED"
echo "======================================="
echo ""
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

bandwidth:
  up: 20 mbps
  down: 100 mbps

fastOpen: true
lazy: true
EOL

echo ""
echo "============== URI ===================="
echo ""

echo "hysteria2://$PASS@$IP:443?sni=bing.com&insecure=1#HY2"

echo ""
echo "============== QR ====================="
echo ""

qrencode -t ANSIUTF8 "hysteria2://$PASS@$IP:443?sni=bing.com&insecure=1#HY2"

echo ""
echo "SOCKS5 : 127.0.0.1:1080"
echo "HTTP   : 127.0.0.1:8989"
echo ""
echo "======================================="
