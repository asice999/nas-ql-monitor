// cron: 0 9 * * *
// new Env('NAS 每日报告');
const { execSync } = require('child_process');
const path = require('path');
const candidates = [
  __dirname,
  '/ql/data/repo/asice999_nas-ql-monitor_main',
  '/ql/data/repo/asice999_nas-ql-monitor',
];
const base = candidates.find(p => {
  try { return require('fs').existsSync(path.join(p, 'daily_report.sh')); } catch { return false; }
}) || __dirname;
execSync(`chmod +x ${path.join(base, 'daily_report.sh')} && ${path.join(base, 'daily_report.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
