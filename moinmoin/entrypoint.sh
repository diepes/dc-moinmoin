#! /bin/bash

export GATEWAY=$(ip route list | awk '/default/ { print $3 }')

if [ -z "$*" ]; then
    ls -l /entry*
    #source /entrypointBackupRestore.sh
    exec gunicorn -b :8080 --forwarded-allow-ips="*" moin_wsgi
else
    exec "$@"
fi
