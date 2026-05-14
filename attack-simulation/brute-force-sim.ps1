# brute-force-sim.ps1
# Simulates RDP/SMB brute force login attempts — LAB USE ONLY
# Run on your Windows VM against itself (localhost) or another lab VM
# This generates Windows Event ID 4625 (failed logon) entries for SIEM testing

#Requires -Version 5.1

param(
    [string]$TargetHost  = "localhost",
    [string]$TargetShare = "C$",
    [int]$AttemptCount   = 10,
    [int]$DelayMs        = 500
)

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "  BRUTE FORCE SIMULATION — LAB USE ONLY" -ForegroundColor Yellow
Write-Host "  Target: $TargetHost | Attempts: $AttemptCount" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host ""

# Fake credentials that will always fail
$FakePasswords = @(
    "Password1", "admin123", "Welcome1", "Summer2024",
    "P@ssw0rd", "Letmein1", "monkey123", "dragon99",
    "qwerty123", "abc123xyz"
)

$FakeUser = "labadmin"
$Successes = 0
$Failures  = 0

for ($i = 0; $i -lt $AttemptCount; $i++) {
    $pass = $FakePasswords[$i % $FakePasswords.Count]
    $secPass = ConvertTo-SecureString $pass -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential("$TargetHost\$FakeUser", $secPass)

    try {
        # Attempt SMB connection — will fail and generate Event 4625
        $null = New-PSDrive -Name "TempDrive$i" -PSProvider FileSystem `
                            -Root "\\$TargetHost\$TargetShare" `
                            -Credential $cred -ErrorAction Stop
        $Successes++
        Write-Host "  [!] Attempt $($i+1): SUCCESS (unexpected in simulation)" -ForegroundColor Red
    }
    catch {
        $Failures++
        Write-Host "  [-] Attempt $($i+1): FAILED — user=$FakeUser pass=$pass" -ForegroundColor Gray
    }

    Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host "  Simulation complete." -ForegroundColor Cyan
Write-Host "  Failed attempts: $Failures | Successes: $Successes" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Check SIEM for Event ID 4625 alerts." -ForegroundColor Green
Write-Host "  SPL: index=siem_windows EventCode=4625 | head 20" -ForegroundColor Green
Write-Host "─────────────────────────────────────────────" -ForegroundColor Cyan
