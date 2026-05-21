# nas-ql-monitor

适合 NAS / Docker / 青龙(QingLong) 用户的通知监控脚本集合。

## 当前包含
- `check_services.sh`：服务在线监控
- `check_docker.sh`：Docker 容器状态监控
- `check_disk.sh`：磁盘空间监控
- `check_cert.sh`：HTTPS 证书到期监控
- `check_backup.sh`：备份结果监控
- `daily_report.sh`：NAS 每日报告
- `check_ddns_ip.sh`：DDNS / 公网 IP 监控
- `check_api_health.sh`：API 健康检查
- `notify.sh`：通用通知模块（Bark / Telegram / stdout）

## 拉库到青龙
```bash
ql repo https://github.com/asice999/nas-ql-monitor.git "" "" ""
```

## 自动创建任务
本仓库已增加青龙自动识别入口脚本：
- `ql_check_ddns_ip.js`
- `ql_check_api_health.js`

如果你的青龙开启了 `AutoAddCron=true`，拉库后会自动识别并创建这两个任务。

也可以手动执行一键安装脚本：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && sh install.sh
```

该安装脚本会使用 `ql` 命令自动创建/重建：
- `NAS DDNS / IP 监控`
- `NAS API 健康检查`

## 推荐目录
青龙通常会把仓库拉到类似目录：
```bash
/ql/data/repo/asice999_nas-ql-monitor/
```

## 通知环境变量
支持两种推送方式，任选其一：

### Bark
```bash
BARK_URL=https://api.day.app/你的key
```

### Telegram
```bash
TG_BOT_TOKEN=你的bot_token
TG_CHAT_ID=你的chat_id
```

## 新增任务说明

### 7) DDNS / IP 监控
命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && IP_API_URL="https://api.ipify.org" DDNS_DOMAINS="home.example.com nas.example.com" ./check_ddns_ip.sh
```
cron：
```cron
*/30 * * * *
```
说明：
- 获取当前公网 IP
- 对比上次记录的 IP
- 检查域名解析是否指向当前公网 IP

### 8) API 健康检查
`API_TARGETS` 格式：多个目标用 `;;` 分隔，每项格式为 `URL|名称|期望状态码|关键字`

命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && API_TARGETS="https://api.example.com/health|主接口|200|ok;;https://example.com|主页|200|Example Domain" ./check_api_health.sh
```
cron：
```cron
*/15 * * * *
```
说明：
- 校验 HTTP 状态码
- 可选校验关键字
- 适合接口、登录页、状态页

## 环境变量总览
- `BARK_URL`
- `TG_BOT_TOKEN`
- `TG_CHAT_ID`
- `SERVICES`
- `CONTAINERS`
- `TARGETS`
- `THRESHOLD`
- `TIMEOUT`
- `CERT_HOSTS`
- `CERT_WARN_DAYS`
- `BACKUP_TARGETS`
- `REPORT_SERVICES`
- `REPORT_CONTAINERS`
- `REPORT_TARGETS`
- `REPORT_CERT_HOSTS`
- `REPORT_BACKUP_TARGETS`
- `IP_API_URL`
- `DDNS_DOMAINS`
- `STATE_DIR`
- `IP_FAMILY`
- `API_TARGETS`

## 返回码约定
- 监控脚本：正常返回 `0`，发现异常返回 `1`
- `daily_report.sh`：始终返回 `0`，避免青龙将日报误判为失败

## 常见问题
### 1. 为什么拉库后没有自动生成任务？
请检查青龙 `AutoAddCron=true`，且仓库中的 `ql_check_*.js` 已被成功拉取。也可以手动执行：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && sh install.sh
```

### 2. DDNS 监控为什么误报？
如果你的域名解析到 CDN / 反代而不是直连家宽公网 IP，就不适合直接做“解析 IP == 当前公网 IP”的校验。

### 3. API 健康检查如何写多个目标？
用 `;;` 分隔多个项，每项格式固定为：
```text
URL|名称|期望状态码|关键字
```
关键字可留空。
