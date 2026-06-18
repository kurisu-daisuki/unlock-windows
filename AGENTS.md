---
name: IP Monitor Helper
description: 帮助配置和使用 IP 变动监控脚本
---

## 能力范围

- 配置 `ip-monitor.ps1` 的邮箱参数（SMTP、端口、授权码）
- 创建 Windows 计划任务实现开机自启
- 排查邮件发送失败问题（检查授权码、防火墙、端口连通性）
- 修改检测间隔时间

## 常用命令

### 设置开机自启（计划任务）

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\path\to\ip-monitor.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "IPMonitor" -Action $action -Trigger $trigger -RunLevel Highest -User SYSTEM
```

### 停止后台监控

```powershell
Get-Process -Name powershell | Where-Object { $_.CommandLine -like "*ip-monitor*" } | Stop-Process
```

### 测试 SMTP 连通性

```powershell
$pass = ConvertTo-SecureString "授权码" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("邮箱@qq.com", $pass)
$c = New-Object Net.Mail.SmtpClient("smtp.qq.com", 587)
$c.EnableSsl = $true; $c.Credentials = $cred; $c.Timeout = 10000
$c.Send("发件@qq.com", "收件@qq.com", "Test", "Test body")
```

## 注意事项

- QQ 邮箱需使用**授权码**而非登录密码
- `disconnect.bat` 必须以**管理员身份**运行
- `ip-state.txt` 已加入 `.gitignore`，不会提交
