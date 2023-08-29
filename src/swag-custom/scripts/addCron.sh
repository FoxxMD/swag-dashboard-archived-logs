#!/bin/bash
echo "5 * * * * /custom-cont-init.d/combineLogs.sh" >> /etc/crontabs/root
echo "Added combine log to crontab"
