# Detection Engineering Guide

## What is Detection Engineering?

Writing rules that convert raw logs into actionable security alerts. Every rule maps to a real attacker behavior from the MITRE ATT&CK framework.

## Detection Rule Anatomy

A good detection rule has:
1. **Data source** — where does the log come from?
2. **Filter** — what specific event(s) to match?
3. **Threshold** — how much activity triggers an alert?
4. **Context enrichment** — what extra info to add (IP, user, hostname)?
5. **MITRE mapping** — which ATT&CK technique does this cover?

## Lab Detection Rules — MITRE ATT&CK Mapping

| Rule | Event Source | Event ID | MITRE Technique | Severity |
|------|-------------|----------|-----------------|----------|
| RDP Brute Force | Windows Security | 4625 | T1110.001 | High |
| SSH Brute Force | Linux auth.log | - | T1110.001 | High |
| Brute Force Success | Windows Security | 4624+4625 | T1110 | Critical |
| PowerShell Encoded Cmd | Sysmon | 1 | T1059.001 / T1027 | High |
| PowerShell Download Cradle | Sysmon | 1 | T1059.001 / T1105 | High |
| PS Spawned by Office | Sysmon | 1 | T1566.001 | Critical |
| PS Network Connection | Sysmon | 3 | T1071 | Medium |
| Privilege Escalation | Windows Security | 4672 | T1078.002 | High |
| Event Log Cleared | Windows System | 1102 | T1070.001 | High |
| Suspicious Script Block | PowerShell | 4104 | T1059.001 | Critical |

## Tuning Detections

**Too many false positives?**
- Increase threshold (e.g., 5 → 10 failures)
- Add whitelist for known IPs or service accounts
- Narrow time window

**Missing real attacks?**
- Lower threshold
- Add more detection patterns
- Check log ingestion gaps

## Alert Triage Workflow (SOC Analyst Process)

```
Alert Fires
    │
    ▼
1. ACKNOWLEDGE — mark alert as under investigation
    │
    ▼
2. CONTEXTUALIZE
   - Who is the source IP/user?
   - Is this a known asset or unknown?
   - What time did this happen?
    │
    ▼
3. CORRELATE
   - Any other alerts from same source?
   - Any successful logins after failures?
   - What else happened on this host?
    │
    ▼
4. DETERMINE
   - True Positive → escalate / respond
   - False Positive → tune the rule, close alert
    │
    ▼
5. DOCUMENT
   - What was found, what action was taken
   - Update runbook if new pattern discovered
```

## Sample Investigation Queries

### Investigate a Brute Force Alert

```splunk
# Find all activity from suspect IP in last hour
index=siem_* src_ip="<SUSPECT_IP>" earliest=-1h
| table _time, host, EventCode, user, action, src_ip

# Check if brute force succeeded
index=siem_windows (EventCode=4624 OR EventCode=4625) src_ip="<SUSPECT_IP>" earliest=-2h
| eval result=if(EventCode=4624,"SUCCESS","FAILURE")
| timechart count BY result
```

```kql
# Kibana KQL
src_ip : "<SUSPECT_IP>" and @timestamp >= now-1h
```

### Investigate PowerShell Alert

```splunk
# Full command line context
index=siem_sysmon EventCode=1 Image=*powershell* host="<AFFECTED_HOST>" earliest=-30m
| table _time, User, CommandLine, ParentImage, ParentCommandLine

# Network connections made by PowerShell
index=siem_sysmon EventCode=3 Image=*powershell* host="<AFFECTED_HOST>" earliest=-30m
| table _time, User, DestinationIp, DestinationPort, Initiated
```
