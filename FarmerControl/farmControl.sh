#!/bin/bash

if [ $# -eq 0 ]; then
  echo "No ID provided. Please provide an ID. Ex: 001."
  exit 1
fi

ID=$1

BASE_URL="http://192.168.10.15"

# MQTT broker
MQTT_SERVER="localhost"
MQTT_PORT=1883
MQTT_USER="emli10"
MQTT_PASSWORD="1Ba4W-D"

MQTT_BROKER="$MQTT_SERVER:$MQTT_PORT"

TOPIC_WA="${ID}/plantwateralarm" # water alarm
TOPIC_PA="${ID}/pumpalarm" # plant alarm
TOPIC_M="${ID}/moisturealarm" # Moisture alarm
TOPIC_P="${ID}/pump"

# LED flags
RED_FLAG=0
GREEN_FLAG=0
YELLOW_FLAG=0
curl "${BASE_URL}/led/red/off"
curl "${BASE_URL}/led/yellow/off"
curl "${BASE_URL}/led/green/off"

# Add a variable to count retries
retryCount=0
maxRetries=1

# WATER ABD PLANT ALARM
# Function to handle received MQTT messages
mqtt_message_handler() {
  # value
  local message_wa="$1"
  local message_pa="$2"
  local message_m="$3"  

  if [ "$message_wa" == "1" ] || [ "$message_pa" == "1" ]; then
    if [ "$message_wa" == "1" ]; then
      echo "Water alarm triggered"
    else
      echo "Plant alarm triggered"
    fi
    if [ "$RED_FLAG" -eq 0 ]; then
      curl "${BASE_URL}/led/red/on"
      RED_FLAG=1
    fi
    if [ "$GREEN_FLAG" -eq 1 ]; then
      curl "${BASE_URL}/led/green/off"
      GREEN_FLAG=0
    fi
    if [ "$YELLOW_FLAG" -eq 1 ]; then
      curl "${BASE_URL}/led/yellow/off"
      YELLOW_FLAG=0
    fi
  else
    echo "No alarms triggered"
    if [ "$RED_FLAG" -eq 1 ]; then
      curl "${BASE_URL}/led/red/off"
      RED_FLAG=0
      if [ "$GREEN_FLAG" -eq 0 ]; then
        curl "${BASE_URL}/led/green/on"
        GREEN_FLAG=1
      fi
    fi
  fi
  
  #if (( message_m < 20 )); then
  #  message_m="1" # Trigger alerm
  #else
  #  message_m="0"
  #fi 
  
# MOISTURE ALARM
  if [ "$message_m" == "1" ]; then
    echo "Soil moisture below threshold"
    if [ "$YELLOW_FLAG" -eq 0 ]; then
      curl "${BASE_URL}/led/yellow/on"
      YELLOW_FLAG=1
    fi
  elif [ "$message_m" == "0" ]; then
    echo "Soil moisture above threshold"
    if [ "$YELLOW_FLAG" -eq 1 ]; then
      curl "${BASE_URL}/led/yellow/off"
      YELLOW_FLAG=0
    fi
    if [ "$RED_FLAG" -eq 0 ]; then
      curl "${BASE_URL}/led/green/on"
      GREEN_FLAG=1
    fi
  fi
  
}

startPump() {
  mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${TOPIC_P}" -m "start"
  sleep 10
  mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "${TOPIC_P}" -m "stop"
}


webserverActive() {
  local ip_address
  ip_address=$(echo "${BASE_URL}" | sed -e 's/http:\/\///')
  if ping -c 1 -w 1 "${ip_address}" > /dev/null 2>&1; then
    echo "Webserver is reachable"
    return 0
  else
    echo "Webserver is not reachable"
    return 1
  fi
}


webserverActive
if [ $? -ne 0 ]; then
  echo "Exiting script due to unreachable webserver"
  exit 1
fi

while true; do
  topics=("${TOPIC_WA}" "${TOPIC_PA}" "${TOPIC_M}")
  values=()

  for topic in "${topics[@]}"; do
    value=$(mosquitto_sub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$topic" -C 1)
    echo "topic: $topic, value: $value"
    values+=("$value")
  done
  
  mqtt_message_handler "${values[@]}"

  button_status=$(curl -s "${BASE_URL}/button/a")
    if [ "$button_status" == "1" ]; then
      sleep 2
      button_status=$(curl -s "${BASE_URL}/button/a")
      if [ "$button_status" == "1" ]; then
        echo "Button pressed, starting pump"
        startPump
      fi
    fi



  webserverActive
  connection_status=$?
  if [ $connection_status -ne 0 ]; then
    retryCount=$((retryCount + 1))

    if [ $retryCount -le $maxRetries ]; then
      echo "Webserver is not reachable, retrying in 30 seconds"
      sleep 30
      continue
    else
      echo "Webserver is still not reachable after retries, exiting the script with error code 1"
      exit 1
    fi
  else
    retryCount=0
  fi

  sleep 1s
done

