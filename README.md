# NAS 青龙监控模板

## 文件
- `notify.sh`：通用通知辅助
- `check_services.sh`：服务在线监控
- `check_docker.sh`：Docker 容器监控
- `check_disk.sh`：磁盘空间监控

## 用法
```sh
chmod +x *.sh
BARK_URL='https://api.day.app/xxxxx' ./check_services.sh
./check_docker.sh
./check_disk.sh
```

## 环境变量
- `BARK_URL`
- `TG_BOT_TOKEN`
- `TG_CHAT_ID`
- `SERVICES`
- `CONTAINERS`
- `TARGETS`
- `THRESHOLD`
- `TIMEOUT`

## 青龙定时建议
- 服务在线：`*/10 * * * *`
- 容器状态：`*/10 * * * *`
- 磁盘空间：`0 */6 * * *`
