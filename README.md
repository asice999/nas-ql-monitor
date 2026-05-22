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
- `notify.sh`：通用通知模块（优先青龙自带通知）

## 拉库到青龙
推荐用这个命令，确保 `.js` 与 `.sh` 都能拉到：

```bash
ql repo https://github.com/asice999/nas-ql-monitor.git "" "" "" main "js sh"
```

## 自动创建任务
本仓库现在已为主要监控脚本都增加了青龙自动识别入口：
- `ql_check_services.js`
- `ql_check_docker.js`
- `ql_check_disk.js`
- `ql_check_cert.js`
- `ql_check_backup.js`
- `ql_daily_report.js`
- `ql_check_ddns_ip.js`
- `ql_check_api_health.js`

如果你的青龙开启了 `AutoAddCron=true`，并且使用上面的 `js sh` 拉库命令，拉库后会像普通青龙脚本一样**直接创建任务**。

也可以手动执行一键安装脚本：
```bash
cd /ql/data/repo/asice999_nas-ql-monitor && sh install.sh
```

该安装脚本会使用 `ql` 命令自动创建/重建全部任务。

## 自动创建的任务列表
- `NAS 服务在线监控`
- `NAS 容器状态监控`
- `NAS 磁盘空间监控`
- `NAS 证书到期监控`
- `NAS 备份结果监控`
- `NAS 每日报告`
- `NAS DDNS / IP 监控`
- `NAS API 健康检查`

## 推荐目录
青龙通常会把仓库拉到类似目录：
```bash
/ql/data/repo/asice999_nas-ql-monitor/
```

## 通知方式
现在默认**优先复用青龙自带通知**，效果和很多电信/签到脚本一致。

优先级如下：
1. 青龙 `sendNotify.js`
2. 青龙常见通知环境变量
3. 输出到任务日志

### 状态变化通知
主要告警脚本已加入**状态记忆**：
- 首次异常时通知
- 持续异常不重复刷屏
- 恢复正常时再发一条恢复通知

状态文件默认保存在仓库目录下的 `.state/`。

### 推荐：直接使用青龙现有通知配置
如果你的青龙已经能给其他脚本发通知，这个仓库通常**无需额外配置**。

### 兼容的常见青龙通知变量
- `BARK_PUSH` / `BARK_URL`
- `TG_BOT_TOKEN`
- `TG_USER_ID`（也兼容 `TG_CHAT_ID`）
- `PUSH_PLUS_TOKEN`
- `QYWX_KEY`
- `DD_BOT_TOKEN`

## 任务入口与默认 cron
- `ql_check_services.js` → `*/10 * * * *`
- `ql_check_docker.js` → `*/10 * * * *`
- `ql_check_disk.js` → `0 */6 * * *`
- `ql_check_cert.js` → `30 8 * * *`
- `ql_check_backup.js` → `20 3 * * *`
- `ql_daily_report.js` → `0 9 * * *`
- `ql_check_ddns_ip.js` → `*/30 * * * *`
- `ql_check_api_health.js` → `*/15 * * * *`

## 业务环境变量
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

## 通知变量（优先复用青龙）
- `BARK_PUSH`
- `BARK_URL`
- `TG_BOT_TOKEN`
- `TG_USER_ID`
- `TG_CHAT_ID`
- `PUSH_PLUS_TOKEN`
- `QYWX_KEY`
- `DD_BOT_TOKEN`

## API_TARGETS 格式
多个目标用 `;;` 分隔，每项格式：
```text
URL|名称|期望状态码|关键字
```
关键字可留空。

示例：
```bash
API_TARGETS="https://api.example.com/health|主接口|200|ok;;https://example.com|主页|200|Example Domain"
```

## 返回码约定
- 监控脚本：正常返回 `0`，发现异常返回 `1`
- `daily_report.sh`：始终返回 `0`，避免青龙将日报误判为失败

## 常见问题
### 1. 为什么还是没有自动生成任务？
请同时检查：
- 青龙 `AutoAddCron=true`
- 拉库命令使用了 `main "js sh"`
- 拉库成功，没有网络/TLS 错误

### 2. 为什么我没有额外配置通知也能收到消息？
因为仓库会优先尝试调用青龙现有的 `sendNotify.js` 或青龙通知变量。

### 3. DDNS 监控为什么误报？
如果你的域名解析到 CDN / 反代而不是直连家宽公网 IP，就不适合直接做“解析 IP == 当前公网 IP”的校验。
