#!/bin/bash
sudo yum update -y

# Using RHEL 6 instead of latest
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL 6
baseurl = https://repos.influxdata.com/rhel/6/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum install telegraf -y
sudo yum install influxdb -y
wget https://dl.influxdata.com/chronograf/releases/chronograf-1.8.5.x86_64.rpm
sudo yum localinstall chronograf-1.8.5.x86_64.rpm -y
wget https://dl.influxdata.com/kapacitor/releases/kapacitor-1.5.5-1.x86_64.rpm
sudo yum localinstall kapacitor-1.5.5-1.x86_64.rpm -y

sudo yum install gcc openssl-devel bzip2-devel libffi-devel jq -y
cd /opt
sudo wget https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tgz
sudo tar xzf Python-3.8.2.tgz
cd Python-3.8.2
sudo ./configure --enable-optimizations
sudo make altinstall
sudo rm -f /opt/Python-3.8.2.tgz