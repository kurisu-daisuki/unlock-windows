# unlock-windows

Windows 远程管理小工具集

## 脚本说明

### 1. `disconnect.bat` — 断开 RDP 保持解锁

断开远程桌面连接，但**不会锁定电脑**，下次连接无需重新输入密码。

**用法：** 以管理员身份运行

```
右键 → 以管理员身份运行
```

---

### 2. `ip-monitor.ps1` — 公网 IP 变动监控

检测公网 IP 地址变化，自动发送邮件通知。

**用法：**

```powershell
# 直接运行
powershell -ExecutionPolicy Bypass -File ip-monitor.ps1

# 自定义邮箱参数
powershell -ExecutionPolicy Bypass -File ip-monitor.ps1 `
    -FromEmail your@qq.com -ToEmail your@qq.com `
    -EmailUser your@qq.com -EmailPassword your_auth_code
```

**参数：**

| 参数 | 默认值 | 说明 |
|---|---|---|
| `SmtpServer` | `smtp.qq.com` | SMTP 服务器 |
| `SmtpPort` | `587` | SMTP 端口 |
| `FromEmail` | `sos_rogi@foxmail.com` | 发件邮箱 |
| `ToEmail` | `sos_rogi@foxmail.com` | 收件邮箱 |
| `EmailUser` | `sos_rogi@foxmail.com` | 邮箱用户名 |
| `EmailPassword` | - | 邮箱密码/授权码 |
| `CheckInterval` | `300` | 检测间隔（秒） |

> **QQ 邮箱授权码获取：** 设置 → 账户 → POP3/IMAP/SMTP服务 → 生成授权码

---

## 注意事项

- `disconnect.bat` 需要**管理员权限**运行
- `ip-monitor.ps1` 建议设为开机启动（计划任务）
- 邮箱凭据已写入脚本，**仓库为私有**，分享前请删除敏感信息

