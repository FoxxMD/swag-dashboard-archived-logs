#!/bin/bash
mkdir -p /dashboard/logs
cat /config/log/nginx/access.log | zcat --force /config/log/nginx/access.log*.gz > /dashboard/logs/combined.log
echo "Combined logs"
