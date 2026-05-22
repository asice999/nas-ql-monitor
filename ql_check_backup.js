// cron: 20 3 * * *
// new Env('NAS 备份结果监控');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'check_backup.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'check_backup.sh')} && ${path.join(base, 'check_backup.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
