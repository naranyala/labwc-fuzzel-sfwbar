#!/bin/bash
# -------------------------------------------------------------------
# OCWS Event Bus API (ocws-emit)
# Standardized IPC for pushing state to the OCWS UI
# -------------------------------------------------------------------

if [ "$#" -lt 2 ]; then
    echo "Usage: ocws-emit <variable_namespace> <value>"
    echo "Example: ocws-emit System.Volume 75"
    exit 1
fi

VAR="$1"
# Support spaces in values by combining the rest of the arguments
shift
VAL="$*"

# Map high-level OCWS API namespaces to the underlying engine variables (sfwbar)
case "$VAR" in
    "System.Volume")       ENGINE_VAR="XVolLevel" ;;
    "System.VolumeMuted")  ENGINE_VAR="XVolMuted" ;;
    "System.Brightness")   ENGINE_VAR="XBrightness" ;;
    "System.Battery")      ENGINE_VAR="XBatLvl" ;;
    "System.BatteryState") ENGINE_VAR="XBatStat" ;;
    "System.Cpu")          ENGINE_VAR="XCpuLoad" ;;
    "System.Memory")       ENGINE_VAR="XMemPct" ;;
    "System.Disk")         ENGINE_VAR="XDiskPct" ;;
    "System.DND")          ENGINE_VAR="XDndState" ;;
    "Network.WiFi")        ENGINE_VAR="XNetState" ;;
    "Network.Bluetooth")   ENGINE_VAR="XBtState" ;;
    "Media.Title")         ENGINE_VAR="XMediaTitle" ;;
    "Media.Artist")        ENGINE_VAR="XMediaArtist" ;;
    "Media.Status")        ENGINE_VAR="XMediaStatus" ;;
    *)                     ENGINE_VAR="$VAR" ;; # Allow raw passthrough for custom plugins
esac

# Check if the value is a string (doesn't start with a number and isn't purely numeric)
# sfwbar requires strings to be quoted in the IPC call
if [[ "$VAL" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    # It's numeric, don't quote
    IPC_CMD="SetVal ${ENGINE_VAR} = ${VAL}"
else
    # It's a string, escape quotes and quote it
    VAL="${VAL//\"/\\\"}"
    IPC_CMD="SetVal ${ENGINE_VAR} = \"${VAL}\""
fi

# Execute IPC using the underlying engine
sfwbar -R "$IPC_CMD" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "OCWS Event Emitted: $VAR -> $VAL"
else
    echo "Failed to connect to OCWS engine (sfwbar might not be running)."
    exit 1
fi
