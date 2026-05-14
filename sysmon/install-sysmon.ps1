# install-sysmon.ps1
# Run as Administrator on Windows VM
# Downloads and installs Sysmon with the lab detection config

#Requires -RunAsAdministrator

$SysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
$SysmonZip = "$env:TEMP\Sysmon.zip"
$SysmonDir = "$env:TEMP\Sysmon"
$ConfigPath = "$PSScriptRoot\sysmon-config.xml"

Write-Host "[*] Downloading Sysmon..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $SysmonUrl -OutFile $SysmonZip

Write-Host "[*] Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $SysmonZip -DestinationPath $SysmonDir -Force

$SysmonExe = Join-Path $SysmonDir "Sysmon64.exe"

Write-Host "[*] Installing Sysmon with lab config..." -ForegroundColor Cyan
& $SysmonExe -accepteula -i $ConfigPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Sysmon installed successfully!" -ForegroundColor Green
    Write-Host "[+] Logs available in: Event Viewer > Applications and Services Logs > Microsoft > Windows > Sysmon > Operational" -ForegroundColor Green
} else {
    Write-Host "[-] Installation failed. Check if Sysmon is already installed." -ForegroundColor Red
    Write-Host "    To update config on existing install: Sysmon64.exe -c $ConfigPath" -ForegroundColor Yellow
}

# Verify service is running
$svc = Get-Service -Name "Sysmon64" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host "[+] Sysmon service is running." -ForegroundColor Green
}

Write-Host "`n[*] Verify events with:" -ForegroundColor Cyan
Write-Host "    Get-WinEvent -LogName 'Microsoft-Windows-Sysmon/Operational' -MaxEvents 10"
