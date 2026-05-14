# powershell-misuse-sim.ps1
# Simulates suspicious PowerShell behaviors for SIEM detection testing — LAB USE ONLY
# Each simulation generates specific Sysmon/PowerShell events to trigger detection rules
# All commands are HARMLESS — they only simulate the patterns, not real attacks

#Requires -Version 5.1

param(
    [ValidateSet("all","encoded","download-cradle","network","script-block","recon")]
    [string]$Scenario = "all"
)

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "  POWERSHELL MISUSE SIMULATION — LAB ONLY" -ForegroundColor Yellow
Write-Host "  Scenario: $Scenario" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

function Run-Scenario {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "[*] Running: $Name" -ForegroundColor Cyan
    try { & $Action } catch { Write-Host "    (expected error: $($_.Exception.Message))" -ForegroundColor DarkGray }
    Write-Host "    [+] Done. Check SIEM for alerts.`n" -ForegroundColor Green
    Start-Sleep -Milliseconds 800
}

# ─── Scenario 1: Encoded Command ─────────────────────────────────────────────
if ($Scenario -in @("all","encoded")) {
    Run-Scenario "Encoded PowerShell Command" {
        # Encode a harmless command — Sysmon Event ID 1 will log the -EncodedCommand flag
        $harmless = "Write-Host 'SIEM lab simulation - encoded command test'"
        $bytes     = [System.Text.Encoding]::Unicode.GetBytes($harmless)
        $encoded   = [Convert]::ToBase64String($bytes)

        # This triggers the -EncodedCommand detection pattern
        $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -NonInteractive -EncodedCommand $encoded" -PassThru -Wait
        Write-Host "    Encoded command executed (PID: $($proc.Id))" -ForegroundColor Gray
    }
}

# ─── Scenario 2: Download Cradle (simulated — no real download) ───────────────
if ($Scenario -in @("all","download-cradle")) {
    Run-Scenario "PowerShell Download Cradle Pattern" {
        # Uses WebClient object — triggers detection without actually downloading
        $wc = New-Object System.Net.WebClient
        # Connect to localhost — will fail but generates the Sysmon network event
        try { $wc.DownloadString("http://127.0.0.1:9999/test") } catch {}
        Write-Host "    WebClient instantiated and network attempt made" -ForegroundColor Gray
    }
}

# ─── Scenario 3: Outbound Network Connection from PowerShell ──────────────────
if ($Scenario -in @("all","network")) {
    Run-Scenario "PowerShell Outbound Network (Sysmon Event ID 3)" {
        # Simple TCP connection attempt — generates Sysmon network connection log
        $client = New-Object System.Net.Sockets.TcpClient
        try { $client.Connect("127.0.0.1", 4444) } catch {}
        $client.Dispose()
        Write-Host "    Network connection attempt to port 4444 logged by Sysmon" -ForegroundColor Gray
    }
}

# ─── Scenario 4: Script Block Logging (EventID 4104) ──────────────────────────
if ($Scenario -in @("all","script-block")) {
    Run-Scenario "Suspicious Script Block Keywords" {
        # These keywords in script blocks trigger 4104 alerts
        # The strings are written but never executed as real attacks
        $simulatedBlock = @'
# SIMULATION ONLY - these strings trigger script block detection
$keyword1 = "AmsiBypass-simulation-test"
$keyword2 = "Invoke-Shellcode-simulation-test"
Write-Host "Script block simulation complete"
'@
        Invoke-Expression $simulatedBlock
    }
}

# ─── Scenario 5: Recon Commands ───────────────────────────────────────────────
if ($Scenario -in @("all","recon")) {
    Run-Scenario "Post-Exploitation Recon (Sysmon Process Creates)" {
        # These are normal commands that get flagged when run from PowerShell in sequence
        $recon = @("whoami", "hostname", "ipconfig /all", "net user", "net localgroup administrators")
        foreach ($cmd in $recon) {
            Write-Host "    Running: $cmd" -ForegroundColor DarkGray
            $null = cmd.exe /c $cmd 2>&1
            Start-Sleep -Milliseconds 300
        }
        Write-Host "    Recon commands generated Sysmon Event ID 1 entries" -ForegroundColor Gray
    }
}

Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  All simulations complete." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Verify in SIEM:" -ForegroundColor Green
Write-Host "  Splunk SPL: index=siem_sysmon EventCode=1 Image=*powershell* | head 20" -ForegroundColor Green
Write-Host "  ELK KQL:    tags:powershell-suspicious OR alert_type:suspicious_powershell" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
