#!/bin/bash

case "$1" in
  exit)
    echo ":: Exit"
    sleep 0.5
    killall -9 Hyprland
    sleep 2
    ;;
  lock)
    echo ":: Lock"
    sleep 0.5
    hyprlock
    ;;
  reboot)
    echo ":: Reboot"
    sleep 0.5
    systemctl reboot
    ;;
  shutdown)
    echo ":: Shutdown"
    sleep 0.5
    systemctl poweroff
    ;;
  suspend)
    echo ":: Suspend"
    sleep 0.5
    systemctl suspend
    ;;
  hibernate)
    echo ":: Hibernate"
    sleep 1
    systemctl hibernate
    ;;
  *)
    echo "Unknown command: $1"
    ;;
esac