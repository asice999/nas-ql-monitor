// cron: 30 8 * * *
// new Env('NAS 证书到期监控');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_cert.sh')} && ${path.join(dir, 'check_cert.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
