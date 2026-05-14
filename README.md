# SIEM Log Monitoring & Threat Detection Lab

**Skills:** SIEM, log parsing, detection engineering, correlation  
**Tools:** Splunk Free / ELK Stack, Sysmon, Windows/Linux VMs  
## Overview

A home lab simulating real Tier 1–2 SOC operations: ingesting logs from Windows (Sysmon) and Linux (auth logs), then detecting simulated attacks including brute force and PowerShell misuse using custom detection rules.

## Project Structure

```
├── splunk/                  # Splunk Free path
│   ├── inputs.conf          # Log source configuration
│   ├── detection-rules/     # SPL saved searches / alerts
│   └── setup-guide.md
├── elk-stack/               # ELK Stack path
│   ├── docker-compose.yml   # Spin up full ELK stack
│   ├── logstash/pipeline/   # Log ingestion pipelines
│   ├── detection-rules/     # Kibana/Watcher alert rules
│   └── setup-guide.md
├── sysmon/                  # Windows log collection
│   ├── sysmon-config.xml    # SwiftOnSecurity-based config
│   └── install-sysmon.ps1
├── attack-simulation/       # Safe attack scripts (lab only)
│   ├── brute-force-sim.ps1
│   ├── powershell-misuse-sim.ps1
│   └── linux-auth-sim.sh
├── logs/sample-logs/        # Reference log samples
└── docs/                    # Guides and runbooks
```

## Lab Setup (Quick Start)

### Option A — Splunk Free
1. Download Splunk Free (up to 500MB/day): https://www.splunk.com/en_us/download/splunk-enterprise.html
2. Install on Windows VM, default port 8000
3. Drop `splunk/inputs.conf` into `$SPLUNK_HOME/etc/system/local/`
4. Import detection rules from `splunk/detection-rules/`
5. See [`splunk/setup-guide.md`](splunk/setup-guide.md) for full walkthrough

### Option B — ELK Stack (Docker)
1. Install Docker Desktop
2. Run: `cd elk-stack && docker-compose up -d`
3. Kibana UI: http://localhost:5601
4. See [`elk-stack/setup-guide.md`](elk-stack/setup-guide.md) for full walkthrough

### Install Sysmon (Windows VM)
```powershell
# Run as Administrator
.\sysmon\install-sysmon.ps1
```

## Detection Use Cases

| # | Attack | Detection Method | Severity |
|---|--------|-----------------|----------|
| 1 | RDP/SSH Brute Force | Failed login threshold (>5 in 60s) | High |
| 2 | PowerShell Misuse | Encoded commands / suspicious cmdlets | High |
| 3 | Privilege Escalation | Event ID 4672 / sudo abuse | Critical |
| 4 | Lateral Movement | Sysmon network connections (Event ID 3) | High |
| 5 | Persistence | Scheduled tasks / registry run keys | Medium |

## Resume Bullets

- "Built Splunk SIEM lab to ingest and analyze Sysmon/Windows logs; created custom detection rules for brute force and PowerShell-based attacks."
- "Simulated real-world attacks and investigated events using ELK Stack, improving response skills and detection logic."

## Lab Environment

- **Windows VM:** Windows 10/11 (VirtualBox/VMware) with Sysmon + Splunk Universal Forwarder
- **Linux VM:** Ubuntu 22.04 with auditd + Filebeat
- **SIEM Host:** Can run on host machine or dedicated VM
