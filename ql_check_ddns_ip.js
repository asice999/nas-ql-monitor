// cron: */30 * * * *
// new Env('NAS DDNS / IP 监控');
const { execSync } = require('child_process');
const path = require('path');
const candidates = [
  __dirname,
  '/ql/data/repo/asice999_nas-ql-monitor_main',
  '/ql/data/repo/asice999_nas-ql-monitor',
];
const base = candidates.find(p => {
  try { return require('fs').existsSync(path.join(p, 'check_ddns_ip.sh')); } catch { return false; }
}) || __dirname;
execSync(`chmod +x ${path.join(base, 'check_ddns_ip.sh')} && ${path.join(base, 'check_ddns_ip.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
