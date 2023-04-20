# Embedded Linux (EMLI)
# University of Southern Denmark
# Raspberry Pico plant watering controller
# Copyright (c) Kjeld Jensen <kjen@sdu.dk> <kj@kjen.dk>
# 2023-04-19, KJ, First version
from machine import Pin, ADC, UART
import utime
from sys import stdin
import uselect
pump_control = Pin(17, Pin.OUT)
pump_water_alarm = Pin(13, Pin.IN)
plant_water_alarm = Pin(9, Pin.IN)
moisture_sensor_pin = Pin(26, mode=Pin.IN)
moisture_sensor = ADC (moisture_sensor_pin)
photo_resistor_pin = Pin(27, mode=Pin.IN)
light_sensor = ADC(photo_resistor_pin)
led_builtin = machine.Pin(25, machine.Pin.OUT)
uart = machine.UART(0, 115200)
def moisture():
    return moisture_sensor.read_u16()/655.36
def light():
    return light_sensor.read_u16()/655.36
def pump_request():
    result = False
    select_result = uselect.select([stdin], [], [], 0)
    while select_result[0]:
        ch = stdin.read(1)
        if ch == 'p':
            result = True
        select_result = uselect.select([stdin], [], [], 0)
    return result
while True:
    led_builtin.toggle()
    if pump_request():
        pump_control.high()
        utime.sleep(1)
        pump_control.low()
    else:
        utime.sleep(1)
    print("%d,%d,%.0f,%.0f" % (plant_water_alarm.value(), pump_water_alarm.value(), moisture(),
light()))
