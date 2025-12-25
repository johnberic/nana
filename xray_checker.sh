#!/bin/bash
## Xray API + MySQL online/offline updater

# Xray API Config
_APISERVER="127.0.0.1:62789"

# Try to automatically locate Xray binary
_XRAY=$(command -v xray || true)
if [[ -z "$_XRAY" ]]; then
    echo "Error: Xray binary not found. Please install Xray or specify its path."
    exit 1
fi

datenow=$(date +"%Y-%m-%d %T")
server_ip=SERVER_IP

# Load MySQL credentials: DB_HOST / DB_USER / DB_PASS / DB_NAME
. /etc/xray/.db-base

# ======================================================
# 1) Fetch XRAY stats
# ======================================================
DATA="$($_XRAY api statsquery --server=$_APISERVER 2>/dev/null)"

# ======================================================
# 2) Extract ONLY Xray usernames
# ======================================================
ONLINE_USERS=($(
    echo "$DATA" \
    | grep '"name": "user' \
    | sed -E 's/.*user>>>([^>]+)>>>.*/\1/' \
    | sort -u
))

echo "== Parsed Online Users =="
printf "%s\n" "${ONLINE_USERS[@]}"
echo "========================="

# ======================================================
# 3) If NONE online → mark all XRAY users offline
# ======================================================
if [[ ${#ONLINE_USERS[@]} -eq 0 ]]; then
    echo "[INFO] No users online. Setting all Xray users offline."

    mysql --ssl-verify-server-cert=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE users
SET
    is_connected = 0,
    is_connected_xray = 0,
    active_address = '',
    active_date = ''
WHERE is_connected_xray = 1
  AND active_address = '$server_ip';
EOF

    exit 0
fi

# ======================================================
# 4) Convert usernames → SQL list: ('u1','u2','u3')
# ======================================================
ACTIVE_LIST=$(printf "'%s'," "${ONLINE_USERS[@]}")
ACTIVE_LIST="${ACTIVE_LIST%,}"  # remove last comma

echo "[INFO] SQL Active List: $ACTIVE_LIST"

# ======================================================
# 5) Set detected users as ONLINE
# ======================================================
mysql --ssl-verify-server-cert=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE users
SET
    is_connected = 1,
    is_connected_xray = 1,
    active_address = '$server_ip',
    active_date = '$datenow'
WHERE user_name IN ($ACTIVE_LIST);
EOF

# ======================================================
# 6) All other server users → OFFLINE
# ======================================================
mysql --ssl-verify-server-cert=OFF -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
UPDATE users
SET
    is_connected = 0,
    is_connected_xray = 0,
    active_address = '',
    active_date = ''
WHERE active_address = '$server_ip'
  AND user_name NOT IN ($ACTIVE_LIST);
EOF
