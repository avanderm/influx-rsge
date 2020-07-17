#!/bin/bash
influx <<EOF
CREATE DATABASE grandexchange
EOF

echo "PATH=/bin:/usr/bin:/usr/local/bin" >> mycron
echo "0 */12 * * * cd /home/grandexchange && ./poll_grandexchange.sh" >> mycron
crontab mycron
rm mycron