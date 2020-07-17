#!/bin/bash
influx <<EOF
CREATE DATABASE grandexchange
EOF

crontab -l > mycron
echo "*/2 * * * * cd /home/grandexchange && poll_grandexchange.sh" >> mycron
crontab mycron
rm mycron