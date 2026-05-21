# 2026-05-22 DDNS/API 自动任务扩展补充

- 新增 `check_ddns_ip.sh`：公网 IP 变化与 DDNS 解析一致性监控
- 新增 `check_api_health.sh`：API/页面健康检查
- 新增 `ql_check_ddns_ip.js` 与 `ql_check_api_health.js` 作为青龙自动识别入口
- 新增 `install.sh`，在支持 `ql` 的环境下一键创建/重建对应任务
- API_TARGETS 最终采用 `;;` 分隔多目标，兼容关键字包含空格
