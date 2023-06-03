#!/bin/bash

for ID in 001 # 002 003 ...
do
	/home/pi/waterpumpsystem/read_sensors.sh "${ID}" /dev/ttyACM0 &
	/home/pi/waterpumpsystem/pump.sh "${ID}" /dev/ttyACM0 &
	/home/pi/waterpumpsystem/control_pump.sh "${ID}" &
	/home/pi/waterpumpsystem/farm_control.sh "${ID}" &
done

/home/pi/waterpumpsystem/health.sh &