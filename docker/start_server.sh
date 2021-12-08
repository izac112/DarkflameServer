#!/bin/bash

function set_defaults() {
    DATABASE_PORT=${DATABASE_PORT:-3306}
    DATABASE=${DATABASE:-darkflame}

    if [[ -z $DATABASE_PASSWORD ]]; then
        USE_DATABASE_PASSWORD="No"
    else
        USE_DATABASE_PASSWORD="Yes"
    fi

    CHAT_SERVER_PORT=${CHAT_SERVER_PORT:-2005}
    MAX_CLIENTS=${MAX_CLIENTS:-999}
    EXTERNAL_IP=${EXTERNAL_IP:-localhost}

    echo "Start server with configuration:"
    echo "===== Database Config ========="
    echo "Database: $DATABASE"
    echo "Database host: $DATABASE_HOST"
    echo "Database port: $DATABASE_PORT"
    echo "Database user: $DATABASE_USER"
    echo "Database password set: $USE_DATABASE_PASSWORD"
    echo "===== Other settings =========="
    echo "Chat server port: $CHAT_SERVER_PORT"
    echo "Max clients: $MAX_CLIENTS"
    echo "External IP: $EXTERNAL_IP"
}

function check_sql_connection() {
    until echo '\q' | mysql -h"$DATABASE_HOST" -P"$DATABASE_PORT" -u"$DATABASE_USER" -p"$DATABASE_PASSWORD" $DATABASE; do
        >&2 echo "MySQL/MariaDB is unavailable - sleeping"
        sleep 1
    done
}

function update_ini() {
    INI_FILE=$1
    KEY=$2
    NEW_VALUE=$3
    sed -i "/^$KEY=/s/=.*/=$NEW_VALUE/" $INI_FILE
}

function update_database_ini_values_for() {
    INI_FILE=$1
    update_ini $INI_FILE mysql_host $DATABASE_HOST
    update_ini $INI_FILE mysql_database $DATABASE
    update_ini $INI_FILE mysql_username $DATABASE_USER
    update_ini $INI_FILE mysql_password $DATABASE_PASSWORD
    if [[ "$INI_FILE" != "worldconfig.ini" ]]; then
        update_ini $INI_FILE external_ip $EXTERNAL_IP
    fi
}

function update_ini_values() {
    update_ini worldconfig.ini chat_server_port $CHAT_SERVER_PORT
    update_ini worldconfig.ini max_clients $MAX_CLIENTS

    update_database_ini_values_for masterconfig.ini
    update_database_ini_values_for authconfig.ini
    update_database_ini_values_for chatconfig.ini
    update_database_ini_values_for worldconfig.ini
}

function symlink_client_files() {
    ln -s /client/client/res/macros/ /app/res/macros
    ln -s /client/client/res/BrickModels/ /app/res/BrickModels
    ln -s /client/client/res/chatplus_en_us.txt /app/res/chatplus_en_us.txt
    ln -s /client/client/res/maps/ /app/res/maps
    ln -s /client/client/res/names/ /app/res/names
    ln -s /client/client/locale/locale.xml /app/locale/locale.xml
}

function fdb_to_sqlite() {
    echo "Run fdb_to_sqlite"
    python3 /app/utils/fdb_to_sqlite.py /client/client/res/cdclient.fdb --sqlite_path /client/client/res/CDServer.sqlite

    (
        cd /app/migrations/cdserver
        readarray -d '' entries < <(printf '%s\0' *.sql | sort -zV)
        for entry in "${entries[@]}"; do
            echo "Execute $entry"
            sqlite3 /client/client/res/CDServer.sqlite < $entry
        done
    )

    ln -s /client/client/res/CDServer.sqlite /app/res/CDServer.sqlite
}

set_defaults

check_sql_connection

update_ini_values

if [[ ! -d "/client" ]]; then
    echo "Client not found."
    echo "Did you forgot to mount the client into the \"/client\" directory?"
    exit 1
fi

if [[ ! -f "/client/extracted" ]]; then
    echo "Start client resource extraction"

    python3 /app/utils/pkextractor.py /client/ /client/

    touch /client/extracted
else
    echo "Client already extracted. Skip this step"
    echo "If you want to force re-extract, just delete the file called \"extracted\" in the client directory"
fi

symlink_client_files

fdb_to_sqlite

echo "Start MasterServer"

./MasterServer

tail -f /dev/null