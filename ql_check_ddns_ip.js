// cron: */30 * * * *
// new Env('NAS DDNS / IP 监控');
const { execSync } = require('child_process');
const path = require('path');
const dir = __dirname;
execSync(`chmod +x ${path.join(dir, 'check_ddns_ip.sh')} && ${path.join(dir, 'check_ddns_ip.sh')}`, { stdio: 'inherit', shell: '/bin/sh' });
