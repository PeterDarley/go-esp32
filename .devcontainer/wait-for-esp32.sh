#!/bin/bash

# Check if /dev/ttyUSB0 exists (ESP32 connected)
DEVICE="/dev/ttyUSB0"

echo ""
echo "================================"
echo "ESP32 DevContainer Entrypoint"
echo "================================"
echo ""

if [ ! -e "$DEVICE" ]; then
  echo "✗ ERROR: ESP32 device not found at $DEVICE"
  echo ""
  echo "The ESP32 must be connected via USB before building."
  echo "Please connect the ESP32 and rebuild the container."
  echo ""
  exit 1
fi

echo "✓ ESP32 device detected at $DEVICE"
echo ""
echo "Continuing with container startup..."
echo "================================"
echo ""

# Execute the original entrypoint/cmd
if [ $# -gt 0 ]; then
  exec "$@"
else
  exec /bin/bash
fi
