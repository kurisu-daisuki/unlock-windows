# 自动查找 RDP 会话并断开（保持电脑解锁）
# 需要以管理员身份运行

# 查找正在运行中的 RDP 会话
$sessionInfo = query session | Select-String "rdp-tcp" | Where-Object { $_ -match "运行中" }

if (-not $sessionInfo) {
    Write-Host "❌ 未找到运行中的 RDP 会话" -ForegroundColor Red
    pause
    exit 1
}

# 提取会话 ID（第3列）
$sessionId = ($sessionInfo -split '\s+', 4)[2]

Write-Host "✅ 找到 RDP 会话，ID = $sessionId" -ForegroundColor Green
Write-Host "🔄 正在断开 RDP，电脑将保持解锁状态..." -ForegroundColor Yellow

# 执行 tscon
tscon $sessionId /dest:console

# 如果执行成功，脚本运行到这里时 RDP 已断开
