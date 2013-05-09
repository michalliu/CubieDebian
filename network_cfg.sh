#!/bin/bash
WIRELESS_SSID=("TP-LINK_3300B6" "Tencent-FreeWiFi")
WIRELESS_PSK=("m i a n x i e" "Ohs67000")
WIRELESS_ACTIVE=(1 0)
WIRELESS_IF="wlan0"

cat <<END
allow-hotplug wlan0
iface wlan0 inet dhcp
END

for ((I=0;I<${#WIRELESS_SSID[@]};I++)); do
SSID=${WIRELESS_SSID[$I]}
PSK=${WIRELESS_PSK[$I]}
ACTIVE=${WIRELESS_ACTIVE[$I]}
WPA_PSK=`wpa_passphrase "${SSID}" "${PSK}" | grep psk=[a-f,0-9] | sed 's/.*psk=//'`
if [ $ACTIVE = 1 ];then
    cat <<END
 wpa-ssid ${SSID}
 wpa-psk ${WPA_PSK}
END
else
    cat <<END
# wpa-ssid ${SSID}
# wpa-psk ${WPA_PSK}
END
fi

done
