#!/bin/bash
influx <<EOF
CREATE DATABASE grandexchange
EOF

# crontab -l > mycron
# echo "0 * * * * /opt/collect.sh" >> mycron
# crontab mycron
# rm mycron