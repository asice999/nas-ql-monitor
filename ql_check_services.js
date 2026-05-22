// cron: */10 * * * *
// new Env('NAS 服务在线监控');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_services.sh')} && ${path.join(dir, 'check_services.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
