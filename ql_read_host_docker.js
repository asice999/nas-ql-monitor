// cron: */10 * * * *
// new Env('宿主机 Docker 状态读取');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const candidates = [__dirname, '/ql/data/repo/asice999_nas-ql-monitor_main', '/ql/data/repo/asice999_nas-ql-monitor'];
const base = candidates.find(p => fs.existsSync(path.join(p, 'read_host_docker.sh'))) || __dirname;
try { execSync(`chmod +x ${path.join(base, 'read_host_docker.sh')} && ${path.join(base, 'read_host_docker.sh')}`, { stdio: 'inherit', shell: '/bin/sh' }); process.exit(0); } catch (e) { process.exit(e.status || 1); }
