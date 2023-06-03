#!/bin/bash
MQTT_SERVER="localhost"
MQTT_PORT=1883
MQTT_USER="emli10"
MQTT_PASSWORD="1Ba4W-D"

while true; do
	CPU_TEMP=$(sensors | grep -i temp1 | grep -Eo "[0-9]+\.[0-9]+")

	if nc -zw1 google.com 443; then
	CONNECTION=1
	else
	CONNECTION=0
	fi

	DISKSPACE=$(echo $(df -h --out=pcent / | grep -v 'Use') | sed 's/%//g')

	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t cputemp -m  $CPU_TEMP
	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t connection -m  $CONNECTION
	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t diskspace -m  $DISKSPACE
	sleep 5
done

