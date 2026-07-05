#!/usr/bin/env bash
# bluetooth-menu.sh
# A fuzzel-based Bluetooth menu using bluetoothctl
# Part of the OCWS Bash Utility Collection

notify_msg() {
    if command -v ocws-notify &> /dev/null; then
        ocws-notify "Bluetooth" "$1" "bluetooth-active-symbolic"
    else
        notify-send "Bluetooth" "$1"
    fi
}

POWER_STATE=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$POWER_STATE" ]; then
    CHOICE=$(echo -e "Turn On" | fuzzel -d -p "Bluetooth is Off: ")
    if [ "$CHOICE" = "Turn On" ]; then
        bluetoothctl power on
        notify_msg "Bluetooth Enabled"
    fi
    exit 0
fi

notify_msg "Scanning for devices..."
bluetoothctl scan on &
SCAN_PID=$!
sleep 3
kill $SCAN_PID

DEVICES=$(bluetoothctl devices | awk '{for (i=3; i<=NF; i++) printf $i " "; print "(" $2 ")"}')

if [ -z "$DEVICES" ]; then
    notify_msg "No devices found."
    exit 0
fi

CHOSEN=$(echo -e "Turn Off\n$DEVICES" | fuzzel -d -p "Bluetooth: " -l 10)

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if [ "$CHOSEN" = "Turn Off" ]; then
    bluetoothctl power off
    notify_msg "Bluetooth Disabled"
    exit 0
fi

# Extract MAC address (it is in parentheses at the end)
MAC=$(echo "$CHOSEN" | awk -F'[(|)]' '{print $(NF-1)}')

if [ -n "$MAC" ]; then
    notify_msg "Connecting to $MAC..."
    if bluetoothctl connect "$MAC" | grep -q "Successful"; then
        notify_msg "Connected to $MAC"
    else
        # Try pairing first
        bluetoothctl pair "$MAC"
        bluetoothctl trust "$MAC"
        if bluetoothctl connect "$MAC" | grep -q "Successful"; then
            notify_msg "Paired and connected to $MAC"
        else
            notify_msg "Failed to connect to $MAC"
        fi
    fi
fi
