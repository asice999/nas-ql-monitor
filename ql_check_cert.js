// cron: 30 8 * * *
// new Env('NAS 证书到期监控');
const { execSync } = require('child_process');
const path = require('path');
const candidates = [
  __dirname,
  '/ql/data/repo/asice999_nas-ql-monitor_main',
  '/ql/data/repo/asice999_nas-ql-monitor',
];
const base = candidates.find(p => {
  try { return require('fs').existsSync(path.join(p, 'check_cert.sh')); } catch { return false; }
}) || __dirname;
execSync(`chmod +x ${path.join(base, 'check_cert.sh')} && ${path.join(base, 'check_cert.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
