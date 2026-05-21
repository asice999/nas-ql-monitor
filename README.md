# nas-ql-monitor

适合 NAS / Docker / 青龙(QingLong) 用户的通知监控脚本集合。

## 当前包含
- `check_services.sh`：服务在线监控
- `check_docker.sh`：Docker 容器状态监控
- `check_disk.sh`：磁盘空间监控
- `check_cert.sh`：HTTPS 证书到期监控
- `check_backup.sh`：备份结果监控
- `daily_report.sh`：NAS 每日报告
- `notify.sh`：通用通知模块（Bark / Telegram / stdout）

## 拉库到青龙
```bash
ql repo https://github.com/asice999/nas-ql-monitor.git "" "" ""
```

> 说明：本仓库以 shell 脚本为主，建议拉库后在青龙里手动创建任务命令。

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

## 任务示例

### 1) 服务在线监控
命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && SERVICES="https://你的青龙地址|青龙 https://你的jellyfin地址|Jellyfin" ./check_services.sh
```
cron：
```cron
*/10 * * * *
```

### 2) Docker 容器监控
命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && CONTAINERS="qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome" ./check_docker.sh
```
cron：
```cron
*/10 * * * *
```

### 3) 磁盘空间监控
命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && THRESHOLD=85 TARGETS="/ /volume1 /var/lib/docker" ./check_disk.sh
```
cron：
```cron
0 */6 * * *
```

### 4) 证书到期监控
命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && CERT_HOSTS="example.com api.example.com" CERT_WARN_DAYS=30 ./check_cert.sh
```
cron：
```cron
30 8 * * *
```

### 5) 备份结果监控
`BACKUP_TARGETS` 格式：`路径|最大间隔小时|最小字节数`

命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && BACKUP_TARGETS="/volume1/backup/db.sql.gz|30|1024 /volume1/backup/config.tar.gz|30|1024" ./check_backup.sh
```
cron：
```cron
20 3 * * *
```

### 6) 每日 NAS 日报
命令：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && REPORT_SERVICES="https://你的青龙地址|青龙 https://你的jellyfin地址|Jellyfin" REPORT_CONTAINERS="qinglong postgres-main jellyfin qbittorrent" REPORT_TARGETS="/ /volume1" REPORT_CERT_HOSTS="example.com" REPORT_BACKUP_TARGETS="/volume1/backup/db.sql.gz|30|1024" ./daily_report.sh
```
cron：
```cron
0 9 * * *
```

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

## 返回码约定
- 监控脚本：正常返回 `0`，发现异常返回 `1`
- `daily_report.sh`：始终返回 `0`，避免青龙将日报误判为失败

## 常见问题
### 1. 为什么拉库后没有自动生成任务？
因为本仓库主要是 shell 监控脚本，不是青龙自动识别的 JS 签到脚本，建议手动建任务。

### 2. 容器监控为什么失败？
通常是因为青龙容器里没有 Docker CLI，或没有挂载 Docker Socket。需要确保青龙有权限执行 `docker inspect`。

### 3. 证书监控为什么失败？
请确认目标域名可从当前运行环境访问，且 `443` 端口可连通。

### 4. 备份监控如何写多个目标？
空格分隔多个项，每项格式固定为：
```text
路径|最大间隔小时|最小字节数
```
