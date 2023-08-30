#!/usr/bin/with-contenv bash
echo "0 * * * * /custom-cont-init.d/002-ingestLogs.sh" >> /etc/crontabs/root
echo "Added ingest logs to crontab"
