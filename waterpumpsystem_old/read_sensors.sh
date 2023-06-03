#!/bin/bash
MQTT_SERVER="localhost"
MQTT_PORT=1883
MQTT_USER="emli10"
MQTT_PASSWORD="1Ba4W-D"

if [ $# -eq 0 ]; then
  echo "No ID provided. Please provide an ID and a device"
  exit 1
fi

if [ ! -e "$2" ]; then
  echo "Device does not exits."
  exit 1
fi

ID="$1"
DEVICE="$2" # /dev/ttyACM0

IFS=','
while true; do
	read INPUT < "${DEVICE}"
	read -a strarr <<< "$INPUT"
	strarr[1]=$(echo ${strarr[1]} | tr 01 10) 
	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${ID}"/plantwateralarm -m  ${strarr[0]}
	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${ID}"/pumpalarm -m  ${strarr[1]}
	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${ID}"/moisture -m  ${strarr[2]}
	mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${ID}"/light -m ${strarr[3]}
	echo "${strarr[0]}, ${strarr[1]}, ${strarr[2]}, ${strarr[3]}"
done
