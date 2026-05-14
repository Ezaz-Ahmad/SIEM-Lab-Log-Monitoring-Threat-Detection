# ELK Stack — Lab Setup Guide

## Prerequisites
- Docker Desktop installed (Windows/Mac/Linux)
- At least 8GB RAM (ELK is memory-hungry)
- Port 5601, 9200, 5044 free

## 1. Start ELK Stack

```bash
cd elk-stack
docker-compose up -d

# Check all containers are running
docker-compose ps

# Watch logs
docker-compose logs -f
```

Wait ~2 minutes for Elasticsearch to be healthy, then open **Kibana**: http://localhost:5601

## 2. Install Winlogbeat on Windows VM

Winlogbeat ships Windows Event Logs + Sysmon to Logstash.

```powershell
# Download Winlogbeat (match ELK version — 8.13.0)
Invoke-WebRequest "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.13.0-windows-x86_64.zip" -OutFile winlogbeat.zip
Expand-Archive winlogbeat.zip -DestinationPath C:\winlogbeat

# Edit C:\winlogbeat\winlogbeat.yml
# Set output.logstash.hosts: ["<SIEM_HOST_IP>:5044"]
```

`winlogbeat.yml` key settings:
```yaml
winlogbeat.event_logs:
  - name: Security
    event_id: 4624, 4625, 4648, 4672, 4688, 4698, 4720
  - name: Microsoft-Windows-Sysmon/Operational
  - name: Microsoft-Windows-PowerShell/Operational
    event_id: 4104

output.logstash:
  hosts: ["SIEM_HOST_IP:5044"]
```

Install and start:
```powershell
cd C:\winlogbeat
.\install-service-winlogbeat.ps1
Start-Service winlogbeat
```

## 3. Install Filebeat on Linux VM

```bash
# Ubuntu/Debian
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.13.0-amd64.deb
sudo dpkg -i filebeat-8.13.0-amd64.deb

# Edit /etc/filebeat/filebeat.yml
sudo nano /etc/filebeat/filebeat.yml
```

`filebeat.yml` key settings:
```yaml
filebeat.inputs:
  - type: log
    paths:
      - /var/log/auth.log
      - /var/log/syslog
    fields:
      log_type: linux_auth

output.logstash:
  hosts: ["SIEM_HOST_IP:5044"]
```

```bash
sudo systemctl enable filebeat
sudo systemctl start filebeat
```

## 4. Create Index Patterns in Kibana

1. Open http://localhost:5601
2. Go to **Stack Management > Index Patterns**
3. Create:
   - `siem-logs-*` (main logs)
   - `siem-alerts-*` (triggered alerts)
4. Set `@timestamp` as time field

## 5. Import Detection Rules

```bash
# Import brute force rules
curl -X POST "localhost:5601/api/detection_engine/rules/_import" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: multipart/form-data" \
  --form "file=@detection-rules/brute-force.json"

# Import PowerShell rules
curl -X POST "localhost:5601/api/detection_engine/rules/_import" \
  -H "kbn-xsrf: true" \
  -H "Content-Type: multipart/form-data" \
  --form "file=@detection-rules/powershell-misuse.json"
```

Or manually via Kibana: **Security > Rules > Import**

## 6. Build SIEM Dashboard in Kibana

Go to **Kibana > Dashboard > Create new**

Suggested visualizations:

| Panel | Type | Query |
|-------|------|-------|
| Failed Logins Over Time | Line chart | `alert_type: failed_logon` |
| Top Attack Source IPs | Pie chart | field: `src_ip` |
| PowerShell Alerts | Data table | `tags: powershell-suspicious` |
| Linux SSH Failures | Bar chart | `alert_type: ssh_failed_password` |
| Critical Alerts | Metric | `severity: critical` |

## 7. Test Detection

```powershell
# Windows VM — trigger brute force alerts
.\attack-simulation\brute-force-sim.ps1

# Windows VM — trigger PowerShell alerts
.\attack-simulation\powershell-misuse-sim.ps1
```

```bash
# Linux VM — trigger SSH brute force alerts
bash ./attack-simulation/linux-auth-sim.sh localhost labuser 10
```

Verify in Kibana: **Discover** > index `siem-alerts-*` > filter last 5 minutes

## Architecture

```
Windows VM                          Docker Host
┌───────────────┐                   ┌──────────────────────────────────┐
│ Winlogbeat    │──────────────────▶│ Logstash :5044                   │
│ Sysmon Events │                   │    ↓ (parse + enrich)            │
│ Event Logs    │                   │ Elasticsearch :9200               │
└───────────────┘                   │    ↓                             │
                                    │ Kibana :5601                     │
Linux VM                            │    - Discover                    │
┌───────────────┐                   │    - Dashboards                  │
│ Filebeat      │──────────────────▶│    - Security Alerts             │
│ /var/log/auth │                   └──────────────────────────────────┘
└───────────────┘
```

## Useful Commands

```bash
# Check Elasticsearch health
curl http://localhost:9200/_cluster/health?pretty

# List all SIEM indexes
curl http://localhost:9200/_cat/indices/siem-*?v

# Count alerts today
curl "http://localhost:9200/siem-alerts-$(date +%Y.%m.%d)/_count"

# Stop lab
docker-compose down

# Stop and delete all data (fresh start)
docker-compose down -v
```
