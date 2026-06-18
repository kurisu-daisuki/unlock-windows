@echo off
chcp 65001 >nul
title 断开RDP - 保持解锁

echo 正在查找 RDP 会话...
for /f "tokens=1,3" %%a in ('query session ^| find "rdp-tcp" ^| find "运行中"') do (
    echo 找到 RDP 会话，ID = %%b
    echo 正在断开，电脑将保持解锁状态...
    tscon %%b /dest:console
)

pause
