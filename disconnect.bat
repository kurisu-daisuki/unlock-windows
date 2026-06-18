@echo off
chcp 65001 >nul
title 断开RDP - 保持解锁
setlocal enabledelayedexpansion

:: 查找活跃的 RDP 会话（状态为 Active/运行中）
for /f "tokens=2,3" %%a in ('query session ^| findstr rdp-tcp') do (
    set "state=%%b"
    if "!state!"=="Active" set "id=%%a"
)

if defined id (
    echo 找到活跃 RDP 会话，ID = %id%
    echo 正在断开，电脑将保持解锁...
    tscon %id% /dest:console
) else (
    echo 未找到活跃的 RDP 会话
)

pause

