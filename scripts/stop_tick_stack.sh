#!/bin/bash
isExistApp=`pgrep telegraf`
if [[ -n  $isExistApp ]]; then
    service telegraf stop
fi
isExistApp=`pgrep influxdb`
if [[ -n  $isExistApp ]]; then
    service influxdb stop
fi
isExistApp=`pgrep chronograf`
if [[ -n  $isExistApp ]]; then
    service chronograf stop
fi
isExistApp=`pgrep kapacitor`
if [[ -n  $isExistApp ]]; then
    service kapacitor stop
fi