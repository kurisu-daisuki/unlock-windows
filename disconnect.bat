@echo off
chcp 65001 >nul
title 断开RDP - 保持解锁
setlocal enabledelayedexpansion

:: 查找活跃的 RDP 会话（支持中英文状态）
for /f "tokens=1,3,4" %%a in ('query session ^| findstr rdp-tcp') do (
    if "%%c"=="Active"  set "id=%%b"
    if "%%c"=="运行中"  set "id=%%b"
)

if defined id (
    echo 找到活跃 RDP 会话，ID = !id!
    echo 正在断开，电脑将保持解锁...
    tscon !id! /dest:console
) else (
    echo 未找到活跃的 RDP 会话
)

pause

