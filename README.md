# nas-ql-monitor

适合 NAS / Docker / 青龙(QingLong) 用户的通知监控脚本集合。

## 两种模式
### 1. 青龙容器内直接监控
适合：服务在线、API、DDNS、证书、日报。

### 2. 宿主机采集 + 青龙读取通知（更安全、更稳定）
适合：Docker 容器状态、宿主机磁盘、备份文件。

宿主机负责生成 JSON 状态文件，青龙只读取这些文件并通知。

## 拉库到青龙
```bash
ql repo https://github.com/asice999/nas-ql-monitor.git "" "" "" main "js sh"
```

## 宿主机采集脚本
- `host_collect_docker.sh`
- `host_collect_disk.sh`
- `host_collect_backup.sh`

默认输出目录：
```text
./data/monitor-status
```
建议宿主机改成固定目录，例如：
```text
/volume1/docker/qinglong/data/monitor-status
```
或任何你映射进青龙 `/ql/data/monitor-status` 的目录。

### 宿主机示例
```bash
MONITOR_STATUS_DIR=/volume1/docker/qinglong/data/monitor-status \
HOST_CONTAINERS="qinglong postgres-main sub2api moviepilot-v2 jellyfin emby qbittorrent navidrome" \
sh /volume1/docker/qinglong/data/repo/asice999_nas-ql-monitor_main/host_collect_docker.sh
```

```bash
MONITOR_STATUS_DIR=/volume1/docker/qinglong/data/monitor-status \
HOST_TARGETS="/ /volume1" \
HOST_THRESHOLD=85 \
sh /volume1/docker/qinglong/data/repo/asice999_nas-ql-monitor_main/host_collect_disk.sh
```

```bash
MONITOR_STATUS_DIR=/volume1/docker/qinglong/data/monitor-status \
HOST_BACKUP_TARGETS="/volume1/backup/db.sql.gz|30|1024 /volume1/backup/config.tar.gz|30|1024" \
sh /volume1/docker/qinglong/data/repo/asice999_nas-ql-monitor_main/host_collect_backup.sh
```

## 青龙读取任务
- `ql_read_host_docker.js`
- `ql_read_host_disk.js`
- `ql_read_host_backup.js`

对应 shell：
- `read_host_docker.sh`
- `read_host_disk.sh`
- `read_host_backup.sh`

默认读取目录：
```text
/ql/data/monitor-status
```

环境变量：
- `HOST_STATUS_DIR`
- `STATUS_FILE`

### 自动创建任务
执行：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor_main && sh install.sh
```

将自动创建：
- `宿主机 Docker 状态读取`
- `宿主机磁盘状态读取`
- `宿主机备份状态读取`
以及原有 NAS 监控任务。

## 通知方式
默认优先复用青龙自带通知。

## 状态变化通知
主要告警脚本已加入状态记忆：
- 首次异常时通知
- 持续异常不重复刷屏
- 恢复正常时再发一条恢复通知

状态文件默认保存在 `.state/`。

## 日报异常摘要
`daily_report.sh` 会读取 `.state/alert_events.log`，附带最近异常/恢复摘要。
- `REPORT_EVENT_LINES`：默认 `10`
- `REPORT_DISK_WARN`：默认 `85`，仅用于日报中给高使用率磁盘加 `⚠️` 标记，不影响日报每天推送
- `REPORT_HOST_DOCKER`：默认 `true`，日报正文显示宿主机 Docker 当前状态
- `REPORT_HOST_DISK`：默认 `true`，日报正文显示宿主机磁盘当前状态
