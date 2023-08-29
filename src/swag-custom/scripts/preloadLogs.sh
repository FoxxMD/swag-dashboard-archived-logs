#!/bin/bash
mkdir -p /tmp

LOG_DIR=/config/log/nginx
EXT_LOG_DIR=/dashboard/logs

if [ -d "${EXT_LOG_DIR}" ]; then
  LOG_DIR=EXT_LOG_DIR
fi

echo "LOG DIR: $LOG_DIR"

if [ ! -d "${LOG_DIR}" ]; then
  echo "Log DIR does not exist!"
  exit 0
fi

geoip=''

if [ -f "/config/geoip2db/dbip-country-lite.mmdb" ]; then
  geoip="--geoip-database=/config/geoip2db/dbip-country-lite.mmdb"
fi

if [ -f "/config/geoip2db/GeoLite2-City.mmdb" ]; then
  geoip="--geoip-database=/config/geoip2db/GeoLite2-City.mmdb"
fi

compressed=$(find $LOG_DIR -regex '.*access.log.\d*.gz' -print0 | sort -rzV | xargs -r0 zcat)
comLength=${#compressed}
echo "Compressed logs length: $comLength"
if [ "$comLength" -gt "0" ]; then
  zcat --force $LOG_DIR/access.log.*.gz | /usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $geoip -
fi

plain=$(find $LOG_DIR -regex '.*access.log.\d*' -exec cat {} +)
plainLength=${#plain}
echo "Non-compressed logs length: $plainLength"
if [ "$plainLength" -gt "0" ]; then
  find $LOG_DIR -regex '.*access.log.\d*' -exec cat {} + | /usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $geoip -
fi

# goaccess command to pipe logs into
# |/usr/bin/goaccess -a -o -html --config-file=/dashboard/goaccess.conf $geoip -

## gets all .gz files and outputs them in reverse order
## (remove -r from sort -r to output in normal order)
## then pipes each file name to zcat
# find /config/log/nginx -regex '.*access.log.\d*.gz' -print0 | sort -rzV | xargs -r0 zcat
