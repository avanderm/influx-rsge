#!/bin/bash
service telegraf start
chkconfig -add telegraf

service influxdb start
chkconfig -add influxdb

service chronograf start
chkconfig -add chronograf

service kapacitor start
chkconfig -add kapacitor

service grafana-server start
chkconfig --add grafana-server