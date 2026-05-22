// cron: */10 * * * *
// new Env('NAS 容器状态监控');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_docker.sh')} && ${path.join(dir, 'check_docker.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
