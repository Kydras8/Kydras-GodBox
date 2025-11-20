# Kydras-GodBox

**Unified Windows + WSL2 + Kali + AC1900 “God Mode” Dev & Pentest Workstation**

Kydras-GodBox is a project that turns a single Windows machine (with WSL2 and Kali available) plus a Wavelink AC1900 Wi-Fi adapter into a fully automated dev and red-team workstation.

> For authorized testing and lab use only. You are responsible for how you use these tools.

---

## ✨ Features

- **Windows GOD Mode**
  - One-shot installer to set up:
    - 3x fully elevated Administrator terminals
    - 1x WSL2 terminal
    - 1x Kali terminal
  - Dev stack bootstrap:
    - Git, Node, Python, etc. (configurable)
    - PATH and environment tuning for `K:` and non-system drives

- **WSL2 / Kali Profiles**
  - Offense profile (`offense-init.sh`)
  - Defense profile (`defense-init.sh`)
  - Dev profile (`dev-init.sh`)
  - Cleanroom profile (`cleanroom-init.sh`)

- **AC1900 Wireless Toolkit**
  - Detect and prefer the Wavelink AC1900 adapter
  - Bridge AC1900 into WSL2 and Kali
  - Monitor-mode and packet-capture helpers (lab use)
  - MAC rotation and privacy helpers

- **Zip Builder Mode**
  - One command to package the entire toolkit into a distributable ZIP:
    - Script sources
    - Config templates
    - Logs and reports

---

## 🔧 Project Layout

```text
windows/    # Windows-side PowerShell automation
wsl/        # WSL2 profile scripts
kali/       # Kali setup and tooling
wireless/   # AC1900 detection, bridging, and wireless helpers
packaging/  # Zip builder scripts and manifest
docs/       # Design, architecture, and roadmap
logs/       # Runtime logs (not all committed)
