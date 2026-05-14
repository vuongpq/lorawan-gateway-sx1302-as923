#!/bin/bash

SX1302_RESET_PIN=17
SX1302_POWER_EN_PIN=18
SX1261_RESET_PIN=5
AD5338R_RESET_PIN=13

echo "CoreCell reset..."

# set pins output
pinctrl set $SX1302_RESET_PIN op
pinctrl set $SX1261_RESET_PIN op
pinctrl set $SX1302_POWER_EN_PIN op
pinctrl set $AD5338R_RESET_PIN op

sleep 0.1

# power enable
pinctrl set $SX1302_POWER_EN_PIN dh
sleep 0.1

# sx1302 reset pulse
pinctrl set $SX1302_RESET_PIN dh
sleep 0.1
pinctrl set $SX1302_RESET_PIN dl
sleep 0.1

# sx1261 reset
pinctrl set $SX1261_RESET_PIN dl
sleep 0.1
pinctrl set $SX1261_RESET_PIN dh
sleep 0.1

# adc reset
pinctrl set $AD5338R_RESET_PIN dl
sleep 0.1
pinctrl set $AD5338R_RESET_PIN dh
sleep 0.1

sleep 0.5

echo "CoreCell reset done"
