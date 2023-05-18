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

while true; do
	run_pump=$(mosquitto_sub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${ID}"/activate_pump -C 1)
	if [[ "$run_pump" == 1 ]]; then
		echo -n  'p' > "${DEVICE}"
	fi
done