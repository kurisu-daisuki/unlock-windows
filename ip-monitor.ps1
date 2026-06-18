param(
    [string]$SmtpServer = "smtp.qq.com",
    [int]$SmtpPort = 587,
    [string]$FromEmail = "sos_rogi@foxmail.com",
    [string]$ToEmail = "sos_rogi@foxmail.com",
    [string]$EmailUser = "sos_rogi",
    [string]$EmailPassword = "itoreszmqsgjdegg",
    [int]$CheckInterval = 300
)

$stateFile = Join-Path $PSScriptRoot "ip-state.txt"
$computerName = [Environment]::MachineName

function Get-PublicIP {
    try {
        $ip = (Invoke-WebRequest -Uri "https://api.ipify.org" -TimeoutSec 10).Content.Trim()
        if ($ip -match '^\d+\.\d+\.\d+\.\d+$') { return $ip }
    } catch {}
    try {
        $ip = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -TimeoutSec 10).Content.Trim()
        if ($ip -match '^\d+\.\d+\.\d+\.\d+$') { return $ip }
    } catch {}
    return $null
}

function SendMail($subject, $body) {
    $secPass = ConvertTo-SecureString $EmailPassword -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($EmailUser, $secPass)
    Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl `
        -Credential $cred -From $FromEmail -To $ToEmail `
        -Subject $subject -Body $body -Encoding utf8
}

function SendIPChangedMail($oldIP, $newIP) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $subject = "IP 已变更 - $computerName"
    $body = "电脑: $computerName`r`nTime: $time`r`n旧 IP: $oldIP`r`n新 IP: $newIP"
    SendMail $subject $body
}

Write-Host "=== IP 监控脚本 ===" -ForegroundColor Cyan
Write-Host "发件: $FromEmail" -ForegroundColor Gray

Write-Host "正在检测公网 IP..." -ForegroundColor Yellow
$currentIP = Get-PublicIP
if (!$currentIP) {
    Write-Host "无法获取公网 IP，请检查网络" -ForegroundColor Red
    Read-Host "按 Enter 退出"; exit 1
}
Write-Host "当前公网 IP: $currentIP" -ForegroundColor Green
Set-Content -Path $stateFile -Value $currentIP

$testBody = "电脑: $computerName`r`n公网 IP: $currentIP`r`n`r`nIP 监控脚本已启动"
try {
    SendMail "IP 监控已启动 - $computerName" $testBody
    Write-Host "测试邮件已发送" -ForegroundColor Yellow
} catch {
    Write-Host "发送失败: $_" -ForegroundColor Red
    Read-Host "按 Enter 退出"; exit 1
}

Write-Host "开始监控，每 $CheckInterval 秒检测一次（按 Ctrl+C 停止）" -ForegroundColor Cyan

while ($true) {
    Start-Sleep -Seconds $CheckInterval
    $newIP = Get-PublicIP
    if (!$newIP) { continue }
    $oldIP = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
    if ($oldIP) { $oldIP = $oldIP.Trim() }
    if ($newIP -ne $oldIP) {
        Write-Host "IP 已变更: $oldIP → $newIP" -ForegroundColor Magenta
        try {
            SendIPChangedMail $oldIP $newIP
            Set-Content -Path $stateFile -Value $newIP
            Write-Host "通知邮件已发送" -ForegroundColor Green
        } catch {
            Write-Host "发送失败: $_" -ForegroundColor Red
        }
    }
}
