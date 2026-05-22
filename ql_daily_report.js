// cron: 0 9 * * *
// new Env('NAS 每日报告');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'daily_report.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'daily_report.sh')} && ${path.join(base, 'daily_report.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
