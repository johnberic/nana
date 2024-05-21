#!/bin/bash
source ~/.db-base

datenow=`date +"%Y-%m-%d %T"`

read user_name is_freeze duration <<< $(MYSQL_PWD=$DB_PASS mysql -u $DB_USER -h $DB_HOST -D $DB_NAME -sNe "SELECT user_name, is_freeze, duration FROM users WHERE user_name='$USERNAME'")

if [[ $is_freeze -eq 1 ]]; then
exit -1
else
    if [[ $duration -eq 0 ]]; then
    exit -1
    else
        MYSQL_PWD=$DB_PASS mysql -u $DB_USER -h $DB_HOST -D $DB_NAME  -sse "UPDATE users SET is_connected='1', active_address='TK403', active_date='$datenow', device_connected='1' WHERE user_name='$USERNAME'"
        MYSQL_PWD=$DB_PASS mysql -u $DB_USER -h $DB_HOST -D $DB_NAME  -sse "UPDATE server_list SET online=online+1 WHERE server_ip='TK403'"
    fi
fi