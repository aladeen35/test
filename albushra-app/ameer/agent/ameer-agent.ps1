# Ameer agent for Windows: sends this computer's status to ameer.albushra.app.
# 1) Replace PASTE_TOKEN_HERE with your AMEER_INGEST_TOKEN (keep this file private).
# 2) Save it as %USERPROFILE%\ameer-agent.ps1 and run it once to test.
# 3) Every 5 minutes (run once in PowerShell):
#    schtasks /Create /SC MINUTE /MO 5 /TN AmeerAgent /TR "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File %USERPROFILE%\ameer-agent.ps1"
# It only reads CPU / memory / disk / battery / uptime. It never reads files.

$Token  = "PASTE_TOKEN_HERE"
$Id     = ($env:COMPUTERNAME).ToLower() -replace '[^a-z0-9._-]', '-'
$Name   = $env:COMPUTERNAME
$Kind   = "pc"          # pc | laptop | server
$Url    = "https://albushra.app/__ameer/ingest"

$ErrorActionPreference = "Stop"
$os   = Get-CimInstance Win32_OperatingSystem
$cpu  = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
$bat  = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
if ($bat) { $Kind = "laptop" }

$data = @{
  id         = $Id
  name       = $Name
  kind       = $Kind
  os         = "$($os.Caption) $($os.Version)"
  cpu        = [double]$cpu
  mem        = [math]::Round((1 - $os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 1)
  memTotalGb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
  disk       = [math]::Round((1 - $disk.FreeSpace / $disk.Size) * 100, 1)
  diskFreeGb = [math]::Round($disk.FreeSpace / 1GB, 1)
  uptimeH    = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
  battery    = if ($bat) { [double]$bat.EstimatedChargeRemaining } else { $null }
  charging   = if ($bat) { $bat.BatteryStatus -eq 2 } else { $null }
  every      = 5
}
$body = @{ kind = "device"; data = $data } | ConvertTo-Json -Depth 4 -Compress
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod -Method Post -Uri $Url -ContentType "application/json; charset=utf-8" `
  -Headers @{ Authorization = "Bearer $Token" } -Body ([Text.Encoding]::UTF8.GetBytes($body)) | Out-Null
Write-Output "ok: $Name"
