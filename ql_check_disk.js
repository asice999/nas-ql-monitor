// cron: 0 */6 * * *
// new Env('NAS 磁盘空间监控');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_disk.sh')} && ${path.join(dir, 'check_disk.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
