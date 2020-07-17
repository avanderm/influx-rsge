#!/bin/bash
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum install telegraf
sudo yum install influxdb
wget https://dl.influxdata.com/chronograf/releases/chronograf-1.8.5.x86_64.rpm
sudo yum localinstall chronograf-1.8.5.x86_64.rpm
wget https://dl.influxdata.com/kapacitor/releases/kapacitor-1.5.5-1.x86_64.rpm
sudo yum localinstall kapacitor-1.5.5-1.x86_64.rpm

sudo yum install jq