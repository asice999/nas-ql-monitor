import json
import subprocess
import sys
from datetime import datetime

out = sys.argv[1]
containers = sys.argv[2:]

items = []
ok = True
summary_parts = []

for c in containers:
    try:
        status = subprocess.check_output(
            ['docker', 'inspect', '-f', '{{.State.Status}}', c],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except Exception:
        status = 'missing'
    try:
        restart = subprocess.check_output(
            ['docker', 'inspect', '-f', '{{.RestartCount}}', c],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        restart_i = int(restart or '0')
    except Exception:
        restart_i = 0

    if status != 'running':
        ok = False
    summary_parts.append(f'{c}:{status}(restart={restart_i})')
    items.append({
        'name': c,
        'status': status,
        'restart': restart_i,
    })

obj = {
    'kind': 'docker',
    'ok': ok,
    'time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'summary': '; '.join(summary_parts),
    'items': items,
}

with open(out, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False)
