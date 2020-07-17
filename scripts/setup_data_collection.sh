#!/bin/bash
influx <<EOF
CREATE DATABASE IF NOT EXISTS grand_exchange
EOF

crontab -l > mycron
echo "0 * * * * /opt/collect.sh" >> mycron
crontab mycron
rm mycron