// cron: 0 9 * * *
// new Env('NAS 每日报告');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'daily_report.sh')} && ${path.join(dir, 'daily_report.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
