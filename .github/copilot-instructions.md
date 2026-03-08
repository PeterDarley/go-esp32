 - [x] Verify that the copilot-instructions.md file in the .github directory is created.

 - [x] Clarify Project Requirements

 - [x] Scaffold the Project (converted to Go devcontainer)

 - [x] Replace Rust workspace with Go devcontainer scaffold

 - [x] Install Required Extensions (Go extension suggested)

 - [ ] Scaffold initial Go package / examples

 - [ ] Compile the Project (not applicable — no Go code yet)

 - [ ] Create and Run Task

 - [ ] Launch the Project (build & run in container)

 - [x] Ensure Documentation is Complete

Summary:
- Repository converted from an ESP32 example to a minimal Go devcontainer scaffold.
- Added: [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json), [.devcontainer/Dockerfile](.devcontainer/Dockerfile), [go.mod](go.mod)
- Removed: previous active build sources and manifests; artifacts replaced/archived.
- Retained: ESP32 helper scripts `attach-esp32.ps1`, `check-esp32.sh`, and `flash.sh` for device workflows.
- Next: optionally scaffold a starter Go package, add example code, and test the devcontainer build and tooling.

## Conventions

- When the user says "note X" or "please note X", it means: add X to this file (.github/copilot-instructions.md).
- When the user says "Johnny", they mean the AI agent (GitHub Copilot).

## Host Environment

- **Devcontainer Host OS (container)**: Ubuntu 22.04 LTS (default devcontainer image)

- **Local Host OS**: this file may be edited by people on Linux, macOS, or Windows. If you are
  developing from Windows with WSL2 and need to attach an ESP32 device into the container,
  continue to use `usbipd-win` and the provided `attach-esp32.ps1` script.
  - Note: After a Windows reboot, `usbipd` attachments must be re-applied.
  - Recommended (PowerShell, elevated):
    ```powershell
    powershell -ExecutionPolicy Bypass -File attach-esp32.ps1
    ```
  - Manual `usbipd` flow (Windows host):
    ```powershell
    usbipd list
    usbipd bind --busid <BUSID>
    usbipd attach --wsl --busid <BUSID>
    ```

If you are running directly on Linux or macOS and plan to connect the ESP32 serial port,
you can mount the serial device into the container or open it from the host as appropriate.

## Network

- ESP32 SoftAP gateway IP: **192.168.71.1** (not the default 192.168.4.1)
- WiFi SSID: `peter_bot`
- HTTP server: `http://192.168.71.1/`

