# Embedded Linux - Mini Project about Plant watering System

## Introduction
This project is a automatic watering system for plant. It uses a Rasperry pi pico to read 4 values, moisture, light, water pump alarm and plant water alarm. These values is then sent to a Raspberry pi over UART, which takes care of watering the plant at appropiate times. An ESP8266 is used for a remote control to send a command to water the plant.

The bash scripts which makes up the functionalites lay within the folder waterpumpsystem.

Modified config files on the raspberry pi is in the config_files folder.

Code for the ESP and the pico is in the peripherals folder.

## Technologies

- Python 3.8
- C++
- Bash script
- Any other libraries or technologies used

## Setup

To run this project, you need to follow these steps:

1. Clone the repository:

```bash
git clone https://github.com/ibyou1997/EMLI.git
