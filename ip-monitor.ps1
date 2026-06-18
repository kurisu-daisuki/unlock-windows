# IP 地址变动监控脚本
# 检测公网 IP 变化时自动发送邮件通知
# 用法: 以管理员运行，或设为开机启动

param(
    [string]$SmtpServer = "smtp.qq.com",
    [int]$SmtpPort = 587,
    [string]$FromEmail,
    [string]$ToEmail,
    [string]$EmailUser,
    [string]$EmailPassword,
    [int]$CheckInterval = 300   # 检测间隔（秒），默认5分钟
)

# 存储上次 IP 的文件
$stateFile = Join-Path $PSScriptRoot "ip-state.txt"

# 获取当前公网 IP
function Get-PublicIP {
    try {
        $ip = (Invoke-WebRequest -Uri "https://api.ipify.org" -TimeoutSec 10).Content.Trim()
        if ($ip -match '^\d+\.\d+\.\d+\.\d+$') { return $ip }
    } catch {}
    # 备用接口
    try {
        $ip = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -TimeoutSec 10).Content.Trim()
        if ($ip -match '^\d+\.\d+\.\d+\.\d+$') { return $ip }
    } catch {}
    return $null
}

# 获取本机名称
$computerName = [Environment]::MachineName

# 发送邮件
function Send-IPNotification {
    param($oldIP, $newIP)
    
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $subject = "⚠️ 电脑 IP 已变更 - $computerName"
    $body = @"
电脑：$computerName
时间：$time
旧 IP：$oldIP
新 IP：$newIP
"@

    try {
        $secPass = ConvertTo-SecureString $EmailPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($EmailUser, $secPass)

        Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl `
            -Credential $cred -From $FromEmail -To $ToEmail `
            -Subject $subject -Body $body -Encoding utf8

        Write-Host "✅ 邮件已发送至 $ToEmail" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ 邮件发送失败: $_" -ForegroundColor Red
        return $false
    }
}

# ====================== 一次性模式 ======================
if ($MyInvocation.BoundParameters.Count -gt 0 -or !$FromEmail) {
    if (!$FromEmail) {
        Write-Host "===== IP 监控脚本配置 =====" -ForegroundColor Cyan
        $FromEmail    = Read-Host "发件邮箱"
        $ToEmail      = Read-Host "收件邮箱"
        $EmailUser    = Read-Host "邮箱用户名" -Default $FromEmail
        $EmailPassword = Read-Host "邮箱密码/授权码" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EmailPassword)
        $EmailPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

    Write-Host "`n🔄 正在检测当前公网 IP..." -ForegroundColor Yellow
    $currentIP = Get-PublicIP
    if (!$currentIP) {
        Write-Host "❌ 无法获取公网 IP，请检查网络" -ForegroundColor Red
        pause; exit 1
    }
    Write-Host "✅ 当前公网 IP: $currentIP" -ForegroundColor Green

    # 保存初始 IP
    Set-Content -Path $stateFile -Value $currentIP
    Write-Host "💾 已保存初始 IP 到 $stateFile" -ForegroundColor Gray

    # 发送测试邮件
    $testBody = "电脑：${computerName}`n公网 IP：${currentIP}`n`nIP 监控脚本已启动，IP 变化时将自动通知。"
    $secPass = ConvertTo-SecureString $EmailPassword -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential($EmailUser, $secPass)
    Send-MailMessage -SmtpServer $SmtpServer -Port $SmtpPort -UseSsl `
        -Credential $cred -From $FromEmail -To $ToEmail `
        -Subject "✅ IP 监控已启动 - $computerName" -Body $testBody -Encoding utf8
    Write-Host "📧 测试邮件已发送，请检查收件箱" -ForegroundColor Yellow

    # 进入循环监控
    Write-Host "`n⏳ 开始监控，每 $CheckInterval 秒检测一次..." -ForegroundColor Cyan
    Write-Host "按 Ctrl+C 停止`n" -ForegroundColor Gray

    while ($true) {
        Start-Sleep -Seconds $CheckInterval
        $newIP = Get-PublicIP
        if (!$newIP) { continue }

        $oldIP = Get-Content $stateFile -Raw -ErrorAction SilentlyContinue
        if ($oldIP) { $oldIP = $oldIP.Trim() }

        if ($newIP -ne $oldIP) {
            Write-Host "🔔 IP 已变更: $oldIP → $newIP" -ForegroundColor Magenta
            if (Send-IPNotification -oldIP $oldIP -newIP $newIP) {
                Set-Content -Path $stateFile -Value $newIP
            }
        }
    }
}
