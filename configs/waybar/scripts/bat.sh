#!/bin/bash
battery="/sys/class/power_supply/BAT0"
if [ -d "$battery" ]; then
    capacity=$(cat "$battery/capacity")
    status=$(cat "$battery/status")
    if [ "$status" = "Charging" ]; then
        icon=" "
    elif [ "$capacity" -le 20 ]; then
        icon=" "
    elif [ "$capacity" -le 50 ]; then
        icon=" "
    elif [ "$capacity" -le 80 ]; then
        icon=" "
    else
        icon=" "
    fi
    echo "{\"text\": \"$icon $capacity%\", \"tooltip\": \"Battery: $capacity% ($status)\"}"
else
    echo "{\"text\": \"\", \"tooltip\": \"\"}"
fi
