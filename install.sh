#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${CODEX_TOUCHBAR_TARGET:-/usr/local/bin/codex-touchbar-usage}"
mtmr_dir="${HOME}/Library/Application Support/MTMR"
mtmr_items="${mtmr_dir}/items.json"
icon_target="${mtmr_dir}/codex-touchbar-icon.png"

install -d "$(dirname "$target")"
install -m 0755 "$repo_dir/scripts/codex-touchbar-usage" "$target"
install -d "$mtmr_dir"
install -m 0644 "$repo_dir/examples/codex-touchbar-icon.png" "$icon_target"

if [[ -e "$mtmr_items" ]]; then
  backup="${mtmr_items}.codex-touchbar-usage.bak.$(date +%Y%m%d%H%M%S)"
  cp -p "$mtmr_items" "$backup"
fi

MTMR_ITEMS="$mtmr_items" CODEX_TOUCHBAR_TARGET="$target" python3 - <<'PY'
import json
import os
import tempfile
from pathlib import Path

items_path = Path(os.environ["MTMR_ITEMS"])
script_path = os.environ["CODEX_TOUCHBAR_TARGET"]
icon_path = "~/Library/Application Support/MTMR/codex-touchbar-icon.png"

if items_path.exists():
    items = json.loads(items_path.read_text(encoding="utf-8"))
else:
    items = []
if not isinstance(items, list):
    raise SystemExit(f"MTMR config must be a JSON array: {items_path}")

codex_item = {
    "type": "shellScriptTitledButton",
    "refreshInterval": 60,
    "source": {
        "inline": f"{script_path} 2>/dev/null || echo 'Codex RPC --'"
    },
    "width": 370,
    "align": "left",
    "bordered": False,
    "image": {"filePath": icon_path},
    "actions": [
        {
            "trigger": "singleTap",
            "action": "shellScript",
            "executablePath": "/usr/bin/open",
            "shellArguments": ["-a", "ChatGPT"],
        }
    ],
}

matches = [
    i for i, item in enumerate(items)
    if isinstance(item, dict)
    and item.get("type") == "shellScriptTitledButton"
    and "codex-touchbar-usage" in item.get("source", {}).get("inline", "")
]
if matches:
    items[matches[0]] = codex_item
    for index in reversed(matches[1:]):
        del items[index]
else:
    items.append(codex_item)

items_path.parent.mkdir(parents=True, exist_ok=True)
with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=items_path.parent,
                                prefix="items.json.", delete=False) as handle:
    json.dump(items, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
    temp_path = Path(handle.name)
os.replace(temp_path, items_path)
PY

echo "Installed: $target"
echo "Installed icon: $icon_target"
echo "Updated MTMR config: $mtmr_items"
echo "Restart MTMR to apply: killall MTMR && open /Applications/MTMR.app"
