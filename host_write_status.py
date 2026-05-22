import json, sys

mode, src, out, now, ok_str, summary = sys.argv[1:7]
ok = ok_str.lower() == 'true'
items = []

with open(src, 'r', encoding='utf-8') as f:
    for raw in f:
        line = raw.rstrip('\n')
        if not line:
            continue
        parts = line.split('\t')
        if mode == 'docker':
            name, status, restart = parts
            items.append({"name": name, "status": status, "restart": int(restart)})
        elif mode == 'disk':
            mount, used, free, total = parts
            items.append({"mount": mount, "used": int(used), "free": free, "total": total})
        elif mode == 'backup':
            path, status, exists, age_hours, size = parts
            items.append({
                "path": path,
                "status": status,
                "exists": exists.lower() == 'true',
                "age_hours": int(age_hours),
                "size": int(size),
            })
        else:
            raise SystemExit(f'unknown mode: {mode}')

obj = {"kind": mode, "ok": ok, "time": now, "summary": summary, "items": items}
with open(out, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False)
