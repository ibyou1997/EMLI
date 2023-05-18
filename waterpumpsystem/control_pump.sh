#!/bin/bash

if [ $# -eq 0 ]; then
  echo "No ID provided. Please provide an ID."
  exit 1
fi

# Access the ID and save it in a variable
ID=$1
# Display the ID
echo "The provided ID is: $ID"
# echo "The provided ID is: $MQTT_SERVER"



MQTT_SERVER="localhost"
MQTT_PORT=1883
MQTT_USER="emli10"
MQTT_PASSWORD="1Ba4W-D"

MQTT_PLANT_ALARM_TOPIC="plantwateralarm"
MQTT_WATER_ALARM_TOPIC="pumpalarm"
MQTT_BUTTON_TOPIC="buttonpress"
MQTT_SOIL_MOISTURE_TOPIC="moisture" 
MQTT_SOIL_MOISTURE_TOPIC_ALARM="moisturealarm" 
MQTT_ACTIVATE_PUMP="activate_pump"


MQTT_PLANT_ALARM_TOPIC="${ID}/${MQTT_PLANT_ALARM_TOPIC}"
MQTT_WATER_ALARM_TOPIC="${ID}/${MQTT_WATER_ALARM_TOPIC}"
MQTT_BUTTON_TOPIC="${ID}/${MQTT_BUTTON_TOPIC}"
MQTT_SOIL_MOISTURE_TOPIC="${ID}/${MQTT_SOIL_MOISTURE_TOPIC}"
MQTT_SOIL_MOISTURE_TOPIC_ALARM="${ID}/${MQTT_SOIL_MOISTURE_TOPIC_ALARM}"
MQTT_ACTIVATE_PUMP="${ID}/${MQTT_ACTIVATE_PUMP}"


      
ACTIVATE_MSG="1"
DECTIVATE_MSG="0"

folder_path="/home/pi/waterpumpsystem/temp_files/"
folder_path="${folder_path}${ID}"

if [ ! -d "$folder_path" ]; then
  mkdir -p "$folder_path"
  echo "Folder temp created: $folder_path"
else
  echo "Temp folder already exists: $folder_path"
fi


filename="water_pump_temp.txt"
filename2="water_pump_temp_12_h.txt"
file_path_temp="$folder_path/$filename"
file_temp_12_h="$folder_path/$filename2"

if [ ! -e "$file_path_temp" ]; then
  touch "$file_path_temp"
  echo "File created: $file_path_temp"
else
  echo "File already exists: $file_path_temp"
fi

if [ ! -e "$file_temp_12_h" ]; then
  touch "$file_temp_12_h"
  echo "File created: $file_temp_12_h"
else
  echo "File already exists: $file_temp_12_h"
fi




while true; do
    bAlarm=false
    bActivate=false

    current_time=$(date +%H:%M)
    #echo "Current time: $current_time"

    resv_msg_plant_alarm=$(mosquitto_sub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_PLANT_ALARM_TOPIC" -C 1 )
    resv_msg_alarm_water_alarm=$(mosquitto_sub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_WATER_ALARM_TOPIC" -C 1 )
    resv_msg_moisture=$(mosquitto_sub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_SOIL_MOISTURE_TOPIC" -C 1 )

    
    # Parse the message as a number
    moisture_value=$(echo "$resv_msg_moisture" | tr -d '\n')
    
    if [ "$moisture_value" -lt 25 ]; then
        mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}"  -t "$MQTT_SOIL_MOISTURE_TOPIC_ALARM" -m "$ACTIVATE_MSG"       
    else 
        mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}"  -t "$MQTT_SOIL_MOISTURE_TOPIC_ALARM" -m "$DECTIVATE_MSG" 

    fi

    if [ "$resv_msg_plant_alarm" = "1" ] || [ "$resv_msg_alarm_water_alarm" = "1" ]; then
        
        echo "Alaram is on!!"
        bAlarm=true

    fi

    if [ "$bAlarm" = false ]; then   
        ##################### 12 h thread #########################

        bValid_file=false
        if [ -s "$file_temp_12_h" ]; then
            saved_time_12_h=$(tail -n 1 "$file_temp_12_h")
            bValid_file=true
        fi

        current_timestamp=$(date -d "$current_time" +%s)
        saved_timestamp_12_h=$(date -d "$saved_time_12_h" +%s)
        time_difference_12_h=$((current_timestamp - saved_timestamp_12_h))
        time_difference__12_h=$((time_difference_12_h / 3600))
        
        if [ "$time_difference__12_h" -ge 2 ] || [ "$bValid_file" = false ]; then
              
                mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}"  -t "$MQTT_ACTIVATE_PUMP" -m "$ACTIVATE_MSG" 
                touch "$file_temp_12_h"
                echo "$current_time" > "$file_temp_12_h"
                echo "Time to run 12 h thread!"  
                bActivate=true
        fi
        
        ################  Read soil thread ##################

        if [ "$moisture_value" -lt 25 ]; then
            
            
            saved_time=$(tail -n 1 "$file_path_temp")
            #echo "Last run time from thread: $saved_time"

            current_timestamp=$(date -d "$current_time" +%s)
            saved_timestamp=$(date -d "$saved_time" +%s)
            time_difference=$((current_timestamp - saved_timestamp))

            # Convert time difference to mint
            time_difference_min=$((time_difference / 60))

            # Compare with 60 mint
            if [ "$time_difference_min" -lt 60 ]; then
                b_time_more_than_1_h=0
                echo "The water pump must run maximum once per hour if the soil moisture falls below a certain thresholdd! Sorry, I cant run"
            else
                b_time_more_than_1_h=1
            fi

            # Run pump
            if [ "$b_time_more_than_1_h" -eq 1 ]; then
                mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_ACTIVATE_PUMP" -m "$ACTIVATE_MSG"
                echo "Time to pump water: threshold below 55! and last run is more than 60 min!"
                touch "$file_path_temp"   
                #Write the current time to the file
                echo "$current_time" > "$file_path_temp"                
                bActivate=true
            fi
        fi

        ######################## Button Threa ###########################3

        # Read button 
        resv_msg_button=$(mosquitto_sub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_BUTTON_TOPIC" -C 1 -W 1)     
        if [ "$resv_msg_button" = "1" ]; then
                mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_ACTIVATE_PUMP" -m "$ACTIVATE_MSG"
                echo "Time to pump water: Button presed!"
                bActivate=true
        fi

    fi
    if [ "$bActivate" = false ];then
            mosquitto_pub -h "${MQTT_SERVER}" -p "${MQTT_PORT}" -u "${MQTT_USER}" -P "${MQTT_PASSWORD}" -t "$MQTT_ACTIVATE_PUMP" -m "$DECTIVATE_MSG"
            echo "Not doing anything!"        
    fi

done
