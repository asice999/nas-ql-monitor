// cron: */15 * * * *
// new Env('NAS API 健康检查');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'check_api_health.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'check_api_health.sh')} && ${path.join(base, 'check_api_health.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
