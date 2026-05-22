// cron: 20 3 * * *
// new Env('NAS 备份结果监控');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_backup.sh')} && ${path.join(dir, 'check_backup.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
