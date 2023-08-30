#!/usr/bin/with-contenv bash

echo "**** Checking if existing logs should be preloaded into SWAG dashboard mod... ****"

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

# db file generated by goaccess when data is persisted
# if it already exists we've likely already preloaded on a previous container start
if [ -d "/tmp" ] && [ -f "/tmp/IGLP_LAST_PARSE.db" ]; then
    echo "**** goaccess already has persisted data, skipping ****"
    exit 0
fi

# possible log locations
LOG_DIR=/config/log/nginx
EXT_LOG_DIR=/dashboard/logs

if [ -d "${EXT_LOG_DIR}" ]; then
  LOG_DIR=EXT_LOG_DIR
fi

if [ ! -d "${LOG_DIR}" ]; then
  echo "**** logs not found in known directories, skipping ****"
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

echo "**** Preloading logs into SWAG dashboard ****"

mkdir -p /tmp

# Order of logs processed is important due to how goaccess parses log lines using timestamps
# Must process earlier logs first
# https://github.com/allinurl/goaccess#notes

# Check for and process compressed logs (earlier, rotated out, and archived by nginx)
compressed=$(find $LOG_DIR -regex '.*access.log.\d*.gz' -print0 | sort -rzV | xargs -r0 zcat)
comLength=${#compressed}
echo "**** Compressed logs length: $comLength ****"
if [ "$comLength" -gt "0" ]; then
  zcat --force $LOG_DIR/access.log.*.gz | /usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $GEO_IP -
fi

# Check for and process uncompressed logs (earlier, rotated out by nginx)
plain=$(find $LOG_DIR -regex '.*access.log.\d*' -exec cat {} +)
plainLength=${#plain}
echo "**** Non-compressed logs length: $plainLength ****"
if [ "$plainLength" -gt "0" ]; then
  find $LOG_DIR -regex '.*access.log.\d*' -exec cat {} + | /usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $GEO_IP -
fi

echo "**** Logs preloaded into SWAG dashboard ****"

# goaccess command to pipe logs into
# |/usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $GEO_IP -

## gets all .gz files and outputs them in reverse order
## (remove -r from sort -r to output in normal order)
## then pipes each file name to zcat
# find /config/log/nginx -regex '.*access.log.\d*.gz' -print0 | sort -rzV | xargs -r0 zcat
