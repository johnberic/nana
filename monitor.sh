#!/bin/bash
service=$1
ip=$(ip route get 8.8.8.8 | awk '/src/ {f=NR} f&&NR-1==f' RS=" ")
os="$(neofetch os)"; os="${os##*: }"
distro="$(neofetch distro)"; distro="${distro##*: }"
cpu="$(neofetch cpu --cpu_speed on --cpu_cores off)"; cpu="${cpu##*: }"
memory="$(neofetch memory)"; memory="${memory##*: }"
disk="$(neofetch disk)"; disk="${disk##*: }"
uptime="$(neofetch uptime)"; uptime="${uptime##*: }"
bandwidth=$(vnstat --oneline | cut -d ";" -f 15)

if [[ $service == "ssh" ]];
then
ssh=$(systemctl is-active sshd)
dropbear=$((echo >/dev/tcp/localhost/44) &>/dev/null && echo "active" || echo "inactive")
squid=$(systemctl is-active squid)
ssl=$(systemctl is-active stunnel4)
socket=$((echo >/dev/tcp/localhost/80) &>/dev/null && echo "active" || echo "inactive")
total_sshd=$(netstat -natp | awk "/$ip:22\y/ && /ESTABLISHED/ && /sshd/" | wc -l)
total_dropbear=$(netstat -natp | awk "/$ip:44\y/ && /ESTABLISHED/ && /dropbear/" | wc -l)
total_socket=$(netstat -natp | awk "/$ip:80\y/ && /ESTABLISHED/ && /python/" | wc -l)
total_ssl=$(netstat -natp | awk "/$ip:443\y/ && /ESTABLISHED/ && /stunnel4/" | wc -l)
totalssh=$((total_sshd + total_dropbear + total_socket + total_ssl))
. /root/.ports

output=$(cat <<EOF
{
 "service": "ssh protocol",
 "ip": "$ip",
 "users": "$totalssh",
 "bandwidth": "$bandwidth",
 "os": "$os",
 "distro": "$distro",
 "cpu": "$cpu",
 "memory": "$memory",
 "disk": "$disk",
 "uptime": "$uptime",
 "ssh_port": "$ssh_port - $ssh",
 "dropbear_port": "$dropbear_port - $dropbear",
 "socket_port": "$socket_port - $socket",
 "squid_port": "$squid_port - $squid",
 "ssh_ssl_port": "$ssh_ssl_port - $ssl",
 "dropbear_ssl_port": "$dropbear_ssl_port - $ssl"
