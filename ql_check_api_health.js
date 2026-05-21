// cron: */15 * * * *
// new Env('NAS API 健康检查');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_api_health.sh')} && ${path.join(dir, 'check_api_health.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
