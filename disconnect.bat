@echo off
title 断开RDP - 保持解锁
for /f "tokens=3" %%a in ('query session rdp-tcp 2^>nul') do tscon %%a /dest:console
pause
