#!/bin/bash
# connect-esp32.sh — open a serial terminal to the ESP32
# Usage: ./connect-esp32.sh [device] [baud]
#   device  default: /dev/ttyUSB0
#   baud    default: 115200

set -euo pipefail

DEVICE="${1:-/dev/ttyUSB0}"
BAUD="${2:-115200}"

# ── 1. Ensure device node exists ────────────────────────────────────────────
if [ ! -e "$DEVICE" ]; then
  echo "Device $DEVICE not found — attempting to create node (requires --privileged)..."
  # ttyUSB0 = major 188, minor 0; ttyUSB1 = minor 1, etc.
  MINOR="${DEVICE##*ttyUSB}"
  sudo mknod "$DEVICE" c 188 "$MINOR" 2>/dev/null || {
    echo "✗ Could not create $DEVICE."
    echo "  Make sure the ESP32 is plugged in."
    echo "  On Windows host: run attach-esp32.ps1 in an elevated PowerShell."
    exit 1
  }
  sudo chmod 666 "$DEVICE"
  echo "✓ Created $DEVICE"
fi

# ── 2. Fix permissions if needed ────────────────────────────────────────────
if [ ! -r "$DEVICE" ] || [ ! -w "$DEVICE" ]; then
  echo "Fixing permissions on $DEVICE..."
  sudo chmod 666 "$DEVICE"
fi

# ── 3. Ensure a serial terminal tool is available ───────────────────────────
if ! command -v picocom &>/dev/null; then
  echo "picocom not found — installing..."
  sudo apt-get install -y picocom -qq
fi

# ── 4. Connect ───────────────────────────────────────────────────────────────
echo "Connecting to $DEVICE at ${BAUD} baud  (exit: Ctrl-A Ctrl-X)"
echo ""
exec picocom --baud "$BAUD" --flow n --databits 8 --parity n "$DEVICE"
