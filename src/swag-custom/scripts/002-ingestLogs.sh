#!/usr/bin/with-contenv bash

echo "**** Checking if current logs should be ingested... ****"

declare CONF_FILE="/dashboard/goaccess.conf"

# sanity check conf is where we expect it to be
if [ ! -f "${CONF_FILE}" ]; then
    echo "**** goaccess config is not in default location, skipping ****"
    exit 0
fi

declare FILE_CONTENT=$( cat "${CONF_FILE}" )

# only continue if the correct (default) persist/save settings in goaccess conf are found to avoid
# clobbering goaccess data in event of custom user conf
for regex in "db-path\s+/tmp" "persist\s+true" "restore\s+true"
do
if ! [[ " $FILE_CONTENT " =~ $regex ]]
    then
        echo "**** goaccess.conf is not using default settings, skipping ****"
        exit 0
fi
done

# possible log locations
LOG_DIR=/config/log/nginx
EXT_LOG_DIR=/dashboard/logs

if [ -d "${EXT_LOG_DIR}" ]; then
  LOG_DIR=EXT_LOG_DIR
fi

if [ ! -d "${LOG_DIR}" ]; then
  echo "**** log directory not found in known locations, skipping ****"
  exit 0
fi

if [ ! -f "${LOG_DIR}/access.log" ]; then
    echo "**** did not find a log at ${LOG_DIR}/access.log, skipping ****"
    exit 0
fi

# setup geoip db arg based on existence of a db (same as goaccess index.php)
GEO_IP=''

if [ -f "/config/geoip2db/dbip-country-lite.mmdb" ]; then
  GEO_IP="--geoip-database=/config/geoip2db/dbip-country-lite.mmdb"
fi

if [ -f "/config/geoip2db/GeoLite2-City.mmdb" ]; then
  GEO_IP="--geoip-database=/config/geoip2db/GeoLite2-City.mmdb"
fi

mkdir -p /tmp

cat $LOG_DIR/access.log | /usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $GEO_IP -

echo "**** Logs ingested ****"
