// cron: 0 */6 * * *
// new Env('宿主机磁盘状态读取');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'read_host_disk.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'read_host_disk.sh')} && ${path.join(base, 'read_host_disk.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
