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

# Grafana
cat <<EOF | sudo tee /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

sudo yum install grafana -y

sudo yum install gcc openssl-devel bzip2-devel libffi-devel jq -y
if ! command -v "python3.8" &> /dev/null; then
    cd /opt
    sudo wget https://www.python.org/ftp/python/3.8.2/Python-3.8.2.tgz
    sudo tar xzf Python-3.8.2.tgz
    cd Python-3.8.2
    sudo ./configure --enable-optimizations
    sudo make altinstall
    sudo rm -f /opt/Python-3.8.2.tgz
fi