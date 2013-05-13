#!/bin/bash
ipaddr=`/etc/getip.sh`
ipaddr_reversed=`echo $ipaddr | rev`
lockfile='/var/lock/morsemsg'
if [ "$ipaddr" != '' ];then
    if [ -f $lockfile ];then
        rm -f $lockfile
    fi
    /etc/morsemsg.sh $ipaddr_reversed
fi
