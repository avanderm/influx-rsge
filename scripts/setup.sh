#!/bin/bash
influx <<EOF
CREATE DATABASE grandexchange
EOF

echo "0 */12 * * * cd /home/grandexchange && ./poll_grandexchange.sh" >> mycron
crontab mycron
rm mycron