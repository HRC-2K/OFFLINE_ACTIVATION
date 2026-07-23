# 🛡️ OFFLINE ACTIVATION & UTILITY MANAGER

> **An all-in-one Windows automation toolkit for offline gaming, silent software deployment, launcher management, network isolation, and firewall rule automation.**

---

## ⚡ Quick Start

Run the script using the following PowerShell command:

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

### 🎮 2. Offline Gaming Tools

- **Multi-Launcher Firewall Isolator:** Automatically scans drives **C:** through **Z:** for Steam, Ubisoft Connect, Epic Games Launcher, and Rockstar Games Launcher installations, then creates inbound and outbound Windows Firewall rules to block only the selected launcher executables. Your PC, web browser, and all other applications remain connected to the internet—only the blocked launchers lose network access.

- **EA Adapter Offline Tool:** Temporarily disables network adapters to launch the EA App in genuine Offline Mode, restores your internet connection automatically after the game starts, and terminates remaining EA background processes when the game exits.

- **Custom Directory Blocker:** Select any folder to recursively create Windows Firewall rules for every executable (`.exe`) within the directory and its subfolders.

- **One-Click Unblocker:** Removes all firewall rules created by this toolkit, restoring normal network access for previously blocked launchers and applications.

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

## 🔒 Philosophy: Digital Ownership & Offline Control

Modern game launchers often require constant internet access, perform background updates, and collect telemetry—even when you simply want to play games you already own.

This project was created to make offline gaming easier and more convenient by automating repetitive setup tasks.

Its goals are to:

- 🎮 Simplify offline game launching.
- 🔒 Reduce unnecessary launcher connectivity and background telemetry.
- ⚡ Automate repetitive firewall and network configuration.
- 📦 Install commonly used gaming software quickly from official sources.
- 🛠️ Keep everything lightweight, script-based, and easy to use.

The objective is convenience, privacy, and giving users greater control over their own Windows gaming environment.

# ⚠️ Disclaimer

This toolkit is intended to help users manage their Windows gaming environment, install software from official sources, and simplify offline game workflows.

Users are solely responsible for ensuring that their use of this project complies with the license agreements, terms of service, and applicable laws related to the software and games they own.

The author does not encourage software piracy, license circumvention, or any unauthorized use of commercial software.
