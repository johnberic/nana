#!/bin/bash
## xray api + mysql stats script

# Xray API Config
_APISERVER=127.0.0.1:62789

# Try to automatically locate Xray binary
_XRAY=$(command -v xray || true)
if [[ -z "$_XRAY" ]]; then
    echo "Error: Xray binary not found. Please install Xray or specify its path."
    exit 1
fi

datenow=$(date +"%Y-%m-%d %T")
server_ip=SERVER_IP

# MySQL Config
. /etc/xray/.db-base

apidata() {
    local ARGS=
    if [[ $1 == "reset" ]]; then
        ARGS="reset: true"
    fi

    $_XRAY api statsquery --server=$_APISERVER "${ARGS}" \
    | awk '{
        if (match($1, /"name":/)) {
            f=1;
            gsub(/^"|",?$/, "", $2);
            split($2, p, ">>>");
            printf "%s:%s->%s\t", p[1], p[2], p[4];
        }
        else if (match($1, /"value":/) && f) {
            f=0;
            gsub(/"/, "", $2);
            printf "%.0f\n", $2;
        }
        else if (match($0, /}/) && f) {
            f=0;
            print 0;
        }
    }'
}

print_sum() {
    local DATA="$1"
    local PREFIX="$2"
    local SORTED=$(echo "$DATA" | grep "^${PREFIX}" | sort -r)
    local SUM=$(echo "$SORTED" | awk '
        /->up/ { us += $2 }
        /->down/ { ds += $2 }
        END {
            printf "SUM->up:\t%.0f\nSUM->down:\t%.0f\nSUM->TOTAL:\t%.0f\n", us, ds, us + ds;
        }')

    echo -e "${SORTED}\n${SUM}" \
    | numfmt --field=2 --suffix=B --to=iec \
    | column -t
}

process_users_to_mysql() {
    declare -A UP
    declare -A DOWN

    while IFS=$'\t' read -r line; do
        user=$(echo "$line" | awk -F'[:-> \t]+' '/^user:/ {print $2}')
        user="${user%-}"
        dir=$(echo "$line" | awk -F'[:-> \t]+' '/^user:/ {print $3}')
        val=$(echo "$line" | awk '{print $2}')

        [[ -z "$user" || -z "$dir" || -z "$val" ]] && continue

        if [[ "$dir" == "up" ]]; then
            UP["$user"]=$val
        else
            DOWN["$user"]=$val
        fi
    done <<< "$DATA"

    ALL_USERS=($(printf "%s\n" "${!UP[@]}" "${!DOWN[@]}" | sort -u))

    for user in "${ALL_USERS[@]}"; do
        up=${UP[$user]:-0}
        down=${DOWN[$user]:-0}

        mysql --ssl-verify-server-cert=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE users
SET
  xray_upload = xray_upload + $up,
  xray_download = xray_download + $down,
  device_connected = 1,
  is_connected_xray = 1,
  is_connected = 1,
  active_address = '$server_ip',
  active_date = '$datenow'
WHERE user_name = '$user';
EOF
    done
}

# ---------------- MAIN -----------------

DATA=$(apidata "$1")

echo "------------Inbound----------"
print_sum "$DATA" "inbound"
echo "-----------------------------"

echo "------------Outbound---------"
print_sum "$DATA" "outbound"
echo "-----------------------------"

echo
echo "-------------User------------"
print_sum "$DATA" "user"
echo "-----------------------------"

# **IMPORTANT: MySQL update must be called**
process_users_to_mysql
