# 🛡️ OFFLINE ACTIVATION & UTILITY MANAGER

> **A powerful, lightweight Windows automation toolkit for silent software deployment and strict offline activation management.**

---

## ⚡ Quick Start

Run the interactive manager instantly from any PowerShell window without downloading extra files:

### 🔷 Pure PowerShell Version (Recommended)
```powershell
irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/menu_ps.ps1" | iex
```
### 🔶 Batch-Compatible Version
```powershell
irm "https://raw.githubusercontent.com/HRC-2K/OFFLINE_ACTIVATION/main/menu_bat.ps1" | iex
```
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

### 🎮 2. Offline Activation Tools
- EA Adapter Offline Tool: Isolates hardware by temporarily toggling network adapters, boots the EA App into true offline mode, restores internet upon game start, and automatically kills background EA processes on game exit.

- Firewall Isolator: Recursively scans drives C: through Z: to block inbound and outbound rules for Steam, Ubisoft, Epic Games, and Rockstar Launcher directories.

- Custom Directory Blocker: Manually target any folder to recursively block all .exe files inside.

- One-Click Unblocker: Cleanly remove custom or client-specific firewall rules and restore default connectivity.

## 📁 Repository Structure

```text
OFFLINE_ACTIVATION/
├── menu_ps.ps1                    # Master Native PowerShell Menu
├── menu_bat.ps1                   # Master Batch-Execution Menu
├── ALL_in_1.ps1                   # All-In-One Offline Manager (PowerShell)
├── ALL_in_1.bat                   # All-In-One Offline Manager (Batch)
├── EA_Adapter_Offline_Method.ps1  # EA Hardware Isolation Tool (PowerShell)
├── EA_Adapter_Offline_Method.bat  # EA Hardware Isolation Tool (Batch)
├── Steam_Ubi_Epic_RStar.ps1       # Multi-Launcher Firewall Blocker (PowerShell)
└── Steam_Ubi_Epic_RStar.bat       # Multi-Launcher Firewall Blocker (Batch)
```

## 📋 Requirements
###  OS: Windows 10 / 11
### Permissions: Administrator Privileges
### PowerShell: 5.1 or higher
