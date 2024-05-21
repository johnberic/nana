#!/bin/bash
source ~/.db-base
MYSQL_PWD=$DB_PASS mysql -u $DB_USER -h $DB_HOST -D $DB_NAME  -sse "UPDATE users SET is_connected='0', active_address='', active_date='' WHERE user_name='$USERNAME'"
MYSQL_PWD=$DB_PASS mysql -u $DB_USER -h $DB_HOST -D $DB_NAME  -sse "UPDATE server_list SET online=online-1 WHERE server_ip='TK403'"