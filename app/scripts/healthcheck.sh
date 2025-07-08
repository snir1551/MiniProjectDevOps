#!/bin/bash

LOG_FILE="$(dirname "$0")/../healthcheck.log"
echo "$(date): Running health check..." >> "$LOG_FILE"

curl -s http://localhost:3000 > /dev/null && \
echo "$(date): Frontend OK " >> "$LOG_FILE" || \
echo "$(date): Frontend DOWN " >> "$LOG_FILE"

curl -s http://localhost:8080 > /dev/null && \
echo "$(date): Backend OK " >> "$LOG_FILE" || \
echo "$(date): Backend DOWN " >> "$LOG_FILE"