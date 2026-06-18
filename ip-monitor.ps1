param(
    [string]$SmtpServer = "smtp.qq.com",
    [int]$SmtpPort = 465,
    [string]$FromEmail = "sos_rogi@foxmail.com",
    [string]$ToEmail = "sos_rogi@foxmail.com",
    [string]$EmailUser = "sos_rogi",
    [string]$EmailPassword = "itoreszmqsgjdegg",
    [int]$CheckInterval = 300
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$stateFile = Join-Path $PSScriptRoot "ip-state.txt"
$computerName = [Environment]::MachineName

function Get-PublicIP {
    try {
        $ip = (Invoke-WebRequest -UseBasicParsing -Uri "https://api.ipify.org" -TimeoutSec 10).Content.Trim()
        if ($ip -match '^\d+\.\d+\.\d+\.\d+$') { return $ip }
    } catch {}
    try {
        $ip = (Invoke-WebRequest -UseBasicParsing -Uri "https://ifconfig.me/ip" -TimeoutSec 10).Content.Trim()
        if ($ip -match '^\d+\.\d+\.\d+\.\d+$') { return $ip }
    } catch {}
    return $null
}

function SendMail($subject, $body) {
    $secPass = ConvertTo-SecureString $EmailPassword -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($EmailUser, $secPass)
    try {
        $smtp = New-Object Net.Mail.SmtpClient($SmtpServer, $SmtpPort)
        $smtp.EnableSsl = $true
        $smtp.Credentials = $cred
        $smtp.Timeout = 10000
        $smtp.Send($FromEmail, $ToEmail, $subject, $body)
        Write-Host "Mail sent" -ForegroundColor Green
    } finally {
        $smtp.Dispose()
    }
}

function SendIPChangedMail($oldIP, $newIP) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $subject = "IP Changed - $computerName"
    $body = "Computer: $computerName`r`nTime: $time`r`nOld IP: $oldIP`r`nNew IP: $newIP"
    SendMail $subject $body
}

Write-Host "=== IP Monitor ===" -ForegroundColor Cyan
Write-Host "From: $FromEmail" -ForegroundColor Gray

Write-Host "Checking public IP..." -ForegroundColor Yellow
$currentIP = Get-PublicIP
if (!$currentIP) {
    Write-Host "Failed to get public IP" -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit 1
}
Write-Host "Current IP: $currentIP" -ForegroundColor Green
Set-Content -Path $stateFile -Value $currentIP

$testBody = "Computer: $computerName`r`nPublic IP: $currentIP`r`n`r`nIP monitor started."
try {
    SendMail "IP Monitor Started - $computerName" $testBody
    Write-Host "Test email sent" -ForegroundColor Yellow
} catch {
    Write-Host "Send failed: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit 1
}

Write-Host "Monitoring every $CheckInterval seconds (Ctrl+C to stop)" -ForegroundColor Cyan

while ($true) {
    Start-Sleep -Seconds $CheckInterval
    $newIP = Get-PublicIP
    if (!$newIP) { continue }
    $oldIP = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
    if ($oldIP) { $oldIP = $oldIP.Trim() }
    if ($newIP -ne $oldIP) {
        Write-Host "IP changed: $oldIP -> $newIP" -ForegroundColor Magenta
        try {
            SendIPChangedMail $oldIP $newIP
            Set-Content -Path $stateFile -Value $newIP
            Write-Host "Notification sent" -ForegroundColor Green
        } catch {
            Write-Host "Send failed: $_" -ForegroundColor Red
        }
    }
}
