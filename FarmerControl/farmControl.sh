#!/bin/bash

BASE_URL="http://192.168.10.15"

# MQTT broker
MQTT_SERVER="localhost"
MQTT_PORT=1883
MQTT_USER="ladyboy"
MQTT_PASSWORD="goldenshower"

MQTT_BROKER="$MQTT_SERVER:$MQTT_PORT"

TOPIC_WA="wateralarm"
TOPIC_PA="plantalarm"
TOPIC_M="moisture"
TOPIC_P="pump"

# LED flags
RED_FLAG=0
GREEN_FLAG=0
YELLOW_FLAG=0

# Add a variable to count retries
retryCount=0
maxRetries=1

# WATER ABD PLANT ALARM
# Function to handle received MQTT messages
mqtt_message_handler() {
  local topic="$1"
  local message="$2"

  if [ "$topic" == "$TOPIC_WA" ] || [ "$topic" == "$TOPIC_PA" ]; then
    if [ "$message" == "0" ] || [ "$message" == "1" ]; then
      if [ "$topic" == "$TOPIC_WA" ]; then
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
    elif [ "$message" == "2" ] || [ "$message" == "3" ]; then
      if [ "$topic" == "$TOPIC_WA" ]; then
        echo "Water alarm not triggered"
      else
        echo "Plant alarm not triggered"
      fi
      if [ "$RED_FLAG" -eq 1 ]; then
        curl "${BASE_URL}/led/red/off"
        RED_FLAG=0
        if [ "$GREEN_FLAG" -eq 0 ]; then
          curl "${BASE_URL}/led/green/on"
          GREEN_FLAG=1
        fi
      fi
    fi
    
# MOISTURE ALARM
  elif [ "$topic" == "$TOPIC_M" ]; then
    if [ "$message" == "1" ]; then
      echo "Soil moisture below threshold"
      if [ "$YELLOW_FLAG" -eq 0 ]; then
        curl "${BASE_URL}/led/yellow/on"
        YELLOW_FLAG=1
      fi
    elif [ "$message" == "0" ]; then
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
  fi
}

startPump() {
  mosquitto_pub -h "${MQTT_BROKER}" -t "${TOPIC_P}" -m "start"
  sleep 10
  mosquitto_pub -h "${MQTT_BROKER}" -t "${TOPIC_P}" -m "stop"
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
  # Subscribe MQTT
  mosquitto_sub -h "${MQTT_BROKER}" -t "${TOPIC_WA}" -t "${TOPIC_PA}" -t "${TOPIC_M}" | while read -r topic message; do
    mqtt_message_handler "$topic" "$message"
  done

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

