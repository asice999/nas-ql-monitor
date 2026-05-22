// cron: */15 * * * *
// new Env('NAS API 健康检查');
const { execSync } = require('child_process');
const path = require('path');
const candidates = [
  __dirname,
  '/ql/data/repo/asice999_nas-ql-monitor_main',
  '/ql/data/repo/asice999_nas-ql-monitor',
];
const base = candidates.find(p => {
  try { return require('fs').existsSync(path.join(p, 'check_api_health.sh')); } catch { return false; }
}) || __dirname;
execSync(`chmod +x ${path.join(base, 'check_api_health.sh')} && ${path.join(base, 'check_api_health.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
