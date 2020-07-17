#!/bin/bash
influx <<EOF
CREATE DATABASE grandexchange
EOF

echo "*/2 * * * * cd /home/grandexchange && ./poll_grandexchange.sh" >> mycron
crontab mycron
rm mycron