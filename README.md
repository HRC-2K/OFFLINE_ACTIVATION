<!--
    OFFLINE_ACTIVATION Documentation / README
    Copyright (C) 2026 HRC-2K <https://github.com/HRC-2K/OFFLINE_ACTIVATION>

    This documentation is part of the HRC Offline Activation project.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->

# 🛡️ OFFLINE ACTIVATION & UTILITY MANAGER

> **An all-in-one Windows automation toolkit for offline gaming, silent software deployment, launcher management, network isolation, and firewall rule automation.**

---

## ⚡ Quick Start

Run the script using the following PowerShell command:

### 🔷 Pure PowerShell Version 
```powershell
irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/menu_ps.ps1" | iex
```

<img width="350" height="252" alt="1" src="https://github.com/user-attachments/assets/053d2243-c345-47d8-a591-6a239efed6ec" />
<img width="350" height="252" alt="2" src="https://github.com/user-attachments/assets/03d8cfc1-e8e9-4765-a8d4-eea43b8ca776" />
<img width="350" height="252" alt="3" src="https://github.com/user-attachments/assets/796bede0-d8c5-4c76-a0d6-424ea71d1098" />
<img width="350" height="252" alt="4" src="https://github.com/user-attachments/assets/a2dc9882-e700-4426-a4d6-493037577459" />


### 🔷 Download Executable (Recommended)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/HRC-2K/OFFLINE_ACTIVATION?style=for-the-badge&logo=github)](https://github.com/HRC-2K/OFFLINE_ACTIVATION/releases/latest)

<img width="560" height="528" alt="1" src="https://github.com/user-attachments/assets/aec1ffa4-813f-449c-8058-04e5ad850e5d" />
<img width="560" height="528" alt="1 5" src="https://github.com/user-attachments/assets/e674f5e5-74d3-4935-948a-88ca24046a73" />

<img width="560" height="528" alt="2" src="https://github.com/user-attachments/assets/0f1df90d-0a14-4f9f-94bb-c27912c1a9bf" />
<img width="560" height="528" alt="3" src="https://github.com/user-attachments/assets/381b3c75-931c-4b47-bfcc-dcd186fc6f9d" />

📌 Note: Administrator privileges are required to manage network adapters and Windows Firewall rules. The script will automatically request UAC elevation if launched without admin rights.

## ✨ Features & Capabilities
### 🛠️ 1. Silent App Installer & Upgrader
Automatically fetches official setup packages, performs silent background installations, and cleans up temporary setup files:

- [0] Chris Titus Tech Windows Utility

- [1] UltraViewer

- [2] Cloudflare 1.1.1.1 WARP

- [3] Firewall App Blocker (FAB)

- [4-8] Gaming Launchers: Steam, Ubisoft Connect, Epic Games, Rockstar, EA App

- [9-10] Utilities: TcNo Account Switcher, Bulk Crap Uninstaller

### 🎮 2. Offline Gaming Tools

- **Multi-Launcher Firewall Isolator:** Automatically scans drives **C:** through **Z:** for Steam, Ubisoft Connect, Epic Games Launcher, and Rockstar Games Launcher installations, then creates inbound and outbound Windows Firewall rules to block only the selected launcher executables. Your PC, web browser, and all other applications remain connected to the internet—only the blocked launchers lose network access.

- **EA Adapter Offline Tool:** Temporarily disables network adapters to launch the EA App in genuine Offline Mode. Once the game exits, it terminates remaining EA background processes and automatically restores your internet connection after you click OK.

- **Custom Directory Blocker:** Select any folder to recursively create Windows Firewall rules for every executable (`.exe`) within the directory and its subfolders.

- **One-Click Unblocker:** Removes all firewall rules created by this toolkit, restoring normal network access for previously blocked launchers and applications.

## 📁 Repository Structure

```text
OFFLINE_ACTIVATION/
├── menu_ps.ps1                    # Master Native PowerShell Menu
├── AI1G.ps1                       # All-In-One Offline Manager (GUI)
├── ALL_in_1.ps1                   # All-In-One Offline Manager (PowerShell)
├── EAOMG.ps1                      # EA Hardware Isolation Tool (GUI)
├── EA_Adapter_Offline_Method.ps1  # EA Hardware Isolation Tool (PowerShell)
├── SUERG.ps1                      # Multi-Launcher Firewall Blocker (GUI)
├── Steam_Ubi_Epic_RStar.ps1       # Multi-Launcher Firewall Blocker (PowerShell)
```

## 📋 Requirements
* OS: Windows 10 / 11
* Permissions: Administrator Privileges
* PowerShell: 5.1 or higher

## 🔒 Philosophy: Digital Ownership & Offline Control

Modern game launchers often require constant internet access, perform background updates, and collect telemetry—even when you simply want to play games you already own.

This project was created to make offline gaming easier and more convenient by automating repetitive setup tasks.

Its goals are to:

- 🎮 Simplify offline game launching.
- 🔒 Reduce unnecessary launcher connectivity and background telemetry.
- ⚡ Automate repetitive firewall and network configuration.
- 📦 Install commonly used gaming software quickly from official sources.
- 🛠️ Keep everything lightweight, script-based, and easy to use.

### The objective is convenience, privacy, and giving users greater control over their own Windows gaming environment.
---


## 📄 License & Copyright

This project is open-source software licensed under the **GNU General Public License v3.0 (GPLv3)**.

* **Developer:** HRC-2K
* **Repository:** [GitHub - HRC-2K/OFFLINE_ACTIVATION](https://github.com/HRC-2K/OFFLINE_ACTIVATION)
* **Full License Text:** See the [`LICENSE`](./LICENSE) file in the repository root for details.

*Copyright (c) 2026 HRC-2K. All rights reserved.*

## ⚠️ Disclaimer

This project is intended for managing offline gaming workflows, launcher network isolation, and installing software from official sources.

Users are responsible for ensuring that their use complies with the applicable software licenses, terms of service, and local laws.

This project does not encourage or support software piracy, illegal distribution, cracked software, license bypasses, or other unauthorized modifications.
