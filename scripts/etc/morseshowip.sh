#!/bin/bash
ipaddr=`/etc/getip.sh`
lockfile='/var/lock/morsemsg'
if [ "$ipaddr" != '' ];then
    if [ -f $lockfile ];then
        rm -f $lockfile
    fi
    /etc/morsemsg.sh $ipaddr
fi
