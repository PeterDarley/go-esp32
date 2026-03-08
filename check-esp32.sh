#!/bin/bash

# Script to check if ESP32 is reachable
# Usage: ./check-esp32.sh

DEVICE="${1:-/dev/ttyUSB0}"
TIMEOUT=2

echo "Checking ESP32 connectivity..."
echo ""

# Check if device exists
if [ ! -e "$DEVICE" ]; then
  echo "✗ Device not found: $DEVICE"
  echo ""
  echo "Possible solutions:"
  echo "  1. Check if ESP32 is physically connected via USB"
  echo "  2. On Windows host, run: powershell -ExecutionPolicy Bypass -File attach-esp32.ps1"
  echo "  3. Check device permissions: ls -la $DEVICE"
  exit 1
fi

echo "✓ Device exists: $DEVICE"

# Check if device is readable
if [ ! -r "$DEVICE" ]; then
  echo "✗ Device not readable: $DEVICE"
  echo ""
  echo "Try running: sudo chmod 666 $DEVICE"
  exit 1
fi

echo "✓ Device is readable"

# Check if device is writable
if [ ! -w "$DEVICE" ]; then
  echo "✗ Device not writable: $DEVICE"
  echo ""
  echo "Try running: sudo chmod 666 $DEVICE"
  exit 1
fi

echo "✓ Device is writable"

# Try to open the device (basic connectivity check)
# Using timeout to avoid hanging if device isn't responding
if timeout $TIMEOUT bash -c "exec 3<>$DEVICE" 2>/dev/null; then
  exec 3>&-  # Close the file descriptor
  echo "✓ Device is accessible"
  echo ""
  echo "✓ ESP32 appears to be reachable!"
  exit 0
else
  echo "⚠ Device may not be responding"
  echo ""
  echo "The device exists but didn't respond. Possible causes:"
  echo "  1. ESP32 is in a different mode (bootloader, sleep, etc.)"
  echo "  2. Device driver issue"
  echo "  3. USB connection issue"
  exit 1
fi
