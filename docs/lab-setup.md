# Lab Environment Setup

## Overview

This lab requires 2–3 machines (physical or VMs):

| Role | OS | Purpose |
|------|----|---------|
| SIEM Host | Windows 10/11 or Ubuntu 22.04 | Runs Splunk or ELK Stack |
| Windows Victim VM | Windows 10/11 | Generates Sysmon + Event Logs |
| Linux Victim VM | Ubuntu 22.04 | Generates auth/syslog events |

> Tip: All three can run on one physical machine using VirtualBox (free) with 16GB RAM.

## VM Setup — Windows (VirtualBox)

1. Download Windows 10 ISO: https://www.microsoft.com/en-us/software-download/windows10
2. Create VM: 4GB RAM, 60GB disk, NAT or Host-Only network
3. Install Windows 10
4. Install Sysmon: `.\sysmon\install-sysmon.ps1`
5. Enable PowerShell logging (see `splunk/setup-guide.md`)
6. Install Splunk Universal Forwarder OR Winlogbeat (depending on SIEM choice)

## VM Setup — Linux (VirtualBox)

```bash
# Ubuntu 22.04 minimal install
sudo apt update && sudo apt install -y openssh-server auditd

# Enable auditd
sudo systemctl enable auditd
sudo systemctl start auditd

# Install Filebeat or Splunk UF (depending on SIEM choice)
```

## Network Setup

Recommended: **Host-Only Network** so all VMs can communicate but are isolated from internet.

VirtualBox: File > Host Network Manager > Create (`192.168.56.0/24`)

| Machine | IP |
|---------|----|
| SIEM Host | 192.168.56.10 |
| Windows VM | 192.168.56.20 |
| Linux VM | 192.168.56.30 |

## Quick Checklist

- [ ] SIEM (Splunk or ELK) running and accessible via browser
- [ ] Sysmon installed on Windows VM with lab config
- [ ] PowerShell Script Block Logging enabled (EventID 4104)
- [ ] Winlogbeat / Splunk UF sending events to SIEM
- [ ] Filebeat / Splunk UF sending Linux auth logs
- [ ] SIEM indexes/index patterns created
- [ ] Detection rules imported
- [ ] Test: run `brute-force-sim.ps1` → verify alert appears in SIEM
- [ ] Test: run `powershell-misuse-sim.ps1` → verify alert appears in SIEM
- [ ] Dashboard created with key panels
