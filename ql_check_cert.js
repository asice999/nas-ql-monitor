// cron: 30 8 * * *
// new Env('NAS 证书到期监控');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'check_cert.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'check_cert.sh')} && ${path.join(base, 'check_cert.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
