# Splunk Free — Lab Setup Guide

## 1. Download & Install

1. Go to https://www.splunk.com/en_us/download/splunk-enterprise.html
2. Create free account → download **Splunk Enterprise** (free trial / free license for ≤500MB/day)
3. Install on your SIEM host (Windows or Linux)
4. Default web UI: http://localhost:8000

## 2. Configure Log Ingestion

### On the SIEM Host (Windows)
Copy `inputs.conf` to Splunk:
```
copy inputs.conf "C:\Program Files\Splunk\etc\system\local\inputs.conf"
```
Restart Splunk:
```
"C:\Program Files\Splunk\bin\splunk.exe" restart
```

### For Linux VM Logs (Universal Forwarder)
1. Download Splunk Universal Forwarder on Linux VM
2. Configure to forward to your SIEM host:
```bash
./splunk add forward-server <SIEM_HOST_IP>:9997
./splunk add monitor /var/log/auth.log -index siem_linux -sourcetype linux_secure
./splunk restart
```

### Enable Receiving on SIEM Host
In Splunk Web: Settings > Forwarding and receiving > Configure receiving > Add port 9997

## 3. Create Indexes

In Splunk Web: Settings > Indexes > New Index

Create these indexes:
- `siem_windows` — Windows Event Logs
- `siem_sysmon` — Sysmon Events
- `siem_powershell` — PowerShell Logs
- `siem_linux` — Linux auth/syslog

## 4. Install Sysmon on Windows VM

```powershell
# On Windows VM (as Administrator)
.\sysmon\install-sysmon.ps1
```

## 5. Enable PowerShell Logging (Windows VM)

Run in PowerShell as Admin:
```powershell
# Enable Script Block Logging (generates EventID 4104)
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
New-Item -Path $regPath -Force
Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1

# Enable Module Logging
$regPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
New-Item -Path $regPath2 -Force
Set-ItemProperty -Path $regPath2 -Name "EnableModuleLogging" -Value 1
```

## 6. Import Detection Rules

In Splunk Web:
1. Go to **Settings > Searches, Reports, and Alerts**
2. Click **New Saved Search**
3. Copy/paste each rule from `detection-rules/brute-force.spl` and `detection-rules/powershell-misuse.spl`
4. Set up **Alert Actions** (email, webhook, or add to triggered alerts)

## 7. Test Detection

Run simulations from `attack-simulation/`:
```powershell
# Brute force simulation
.\attack-simulation\brute-force-sim.ps1 -AttemptCount 10

# PowerShell misuse simulation
.\attack-simulation\powershell-misuse-sim.ps1 -Scenario all
```

Check Splunk: Search & Reporting > run:
```
index=siem_windows EventCode=4625 | head 20
```

## 8. Build Dashboards

In Splunk Web: Dashboards > Create New Dashboard

Suggested panels:
- **Failed Logins Over Time** — `index=siem_windows EventCode=4625 | timechart count`
- **Top Failed Login Sources** — `index=siem_windows EventCode=4625 | top src_ip`
- **PowerShell Activity** — `index=siem_sysmon EventCode=1 Image=*powershell* | timechart count`
- **Linux Auth Failures** — `index=siem_linux "Failed password" | timechart count`

## Architecture Diagram

```
Windows VM                     SIEM Host (Splunk)
┌────────────────┐             ┌────────────────────────┐
│ Sysmon         │──Events────▶│ Splunk Enterprise       │
│ Event Logs     │             │ Port 8000 (Web UI)      │
│ PowerShell Log │             │                         │
│ UF (port 9997) │             │ Indexes:                │
└────────────────┘             │  - siem_windows         │
                               │  - siem_sysmon          │
Linux VM                       │  - siem_powershell      │
┌────────────────┐             │  - siem_linux           │
│ /var/log/auth  │──Filebeat──▶│                         │
│ auditd         │             │ Detection Alerts        │
│ syslog         │             └────────────────────────┘
└────────────────┘
```
