// cron: */30 * * * *
// new Env('NAS DDNS / IP 监控');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'check_ddns_ip.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'check_ddns_ip.sh')} && ${path.join(base, 'check_ddns_ip.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
