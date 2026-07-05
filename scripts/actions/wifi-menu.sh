#!/usr/bin/env bash
# wifi-menu.sh
# A fuzzel-based Wi-Fi menu using nmcli
# Part of the OCWS Bash Utility Collection

notify_msg() {
    if command -v ocws-notify &> /dev/null; then
        ocws-notify "Wi-Fi" "$1" "network-wireless-symbolic"
    else
        notify-send "Wi-Fi" "$1"
    fi
}

notify_msg "Scanning for networks..."
# Get list of available networks
NETWORKS=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | sed 's/  */ /g' | sed -E "s/WPA*.?\S/ /g" | sed "s/^--/ /g" | sed "s/  //g" | sed "/--/d" | awk '!a[$0]++')

if [ -z "$NETWORKS" ]; then
    notify_msg "No networks found or Wi-Fi disabled."
    exit 1
fi

# Show fuzzel menu
CHOSEN_NETWORK=$(echo -e "Toggle Wi-Fi\n$NETWORKS" | fuzzel -d -p "Wi-Fi: " -l 10)

if [ -z "$CHOSEN_NETWORK" ]; then
    exit 0
fi

if [ "$CHOSEN_NETWORK" = "Toggle Wi-Fi" ]; then
    WIFI_STATE=$(nmcli radio wifi)
    if [ "$WIFI_STATE" = "enabled" ]; then
        nmcli radio wifi off
        notify_msg "Wi-Fi Disabled"
    else
        nmcli radio wifi on
        notify_msg "Wi-Fi Enabled"
    fi
    exit 0
fi

# Extract SSID
CHOSEN_ID=$(echo "$CHOSEN_NETWORK" | sed 's/^[] //')

# Check if network is saved
SAVED_CONNECTIONS=$(nmcli -g NAME connection)
if echo "$SAVED_CONNECTIONS" | grep -qw "$CHOSEN_ID"; then
    nmcli connection up id "$CHOSEN_ID" | grep "successfully" && notify_msg "Connected to $CHOSEN_ID" || notify_msg "Failed to connect to $CHOSEN_ID"
else
    # Prompt for password if secured
    if [[ "$CHOSEN_NETWORK" == *""* ]]; then
        WIFI_PASSWORD=$(fuzzel -d -p "Password for $CHOSEN_ID: ")
        if [ -z "$WIFI_PASSWORD" ]; then
            notify_msg "Connection aborted."
            exit 1
        fi
        nmcli device wifi connect "$CHOSEN_ID" password "$WIFI_PASSWORD" | grep "successfully" && notify_msg "Connected to $CHOSEN_ID" || notify_msg "Failed to connect to $CHOSEN_ID"
    else
        nmcli device wifi connect "$CHOSEN_ID" | grep "successfully" && notify_msg "Connected to $CHOSEN_ID" || notify_msg "Failed to connect to $CHOSEN_ID"
    fi
fi
