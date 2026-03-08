# PowerShell script to attach ESP32 to WSL2 via usbipd
# Interactive:  powershell -ExecutionPolicy Bypass -File attach-esp32.ps1
# Auto mode:    powershell -ExecutionPolicy Bypass -File attach-esp32.ps1 -Auto
#   (used by devcontainer initializeCommand — update AUTO_BUSID if it changes after reboot)
param(
  [switch]$Auto
)

# *** UPDATE THIS if your BUSID changes after a Windows reboot ***
$AUTO_BUSID = "12-4"

# Requires administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
  Write-Host "This script requires Administrator privileges. Please run again as Administrator." -ForegroundColor Red
  # In auto mode (called by VS Code initializeCommand) exit 0 so container still starts
  exit 0
}

if ($Auto) {
  $busid = $AUTO_BUSID
  Write-Host "Auto mode: using BUSID $busid" -ForegroundColor Cyan
} else {
  Write-Host "Listing USB devices..." -ForegroundColor Cyan
  usbipd list

  Write-Host ""
  Write-Host "Enter the BUSID of the ESP32 (e.g., 1-3):" -ForegroundColor Yellow
  $busid = Read-Host "BUSID"

  if ([string]::IsNullOrWhiteSpace($busid)) {
    Write-Host "No BUSID provided. Exiting." -ForegroundColor Red
    exit 1
  }
}

Write-Host ""
Write-Host "Binding device $busid..." -ForegroundColor Cyan
usbipd bind --busid $busid

Write-Host "Attaching device $busid to WSL..." -ForegroundColor Cyan
usbipd attach --wsl --busid $busid

Write-Host ""
Write-Host "Done. ESP32 attached to WSL. Device should now appear at /dev/ttyUSB0" -ForegroundColor Green
