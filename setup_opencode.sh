#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
THEMES="$CONFIG_DIR/themes"
CONF="$CONFIG_DIR/cli.json"

mkdir -p "$THEMES"
cp extras/opencode/deepblue.json "$THEMES/deepblue.json"
cp extras/opencode/neonvoid.json "$THEMES/neonvoid.json"

python3 - "$CONF" <<'PY'
import json
import shutil
import sys
from pathlib import Path

path = Path(sys.argv[1])
if path.exists():
    config = json.loads(path.read_text())
    if not isinstance(config, dict):
        raise SystemExit(f"expected a JSON object in {path}")
else:
    config = {}

config.setdefault("$schema", "https://opencode.ai/v2/cli.json")
theme = config.get("theme")
if not isinstance(theme, dict):
    theme = {}
    config["theme"] = theme
theme["name"] = "neonvoid"
theme["mode"] = "dark"

updated = json.dumps(config, indent=2) + "\n"
current = path.read_text() if path.exists() else None
if current != updated:
    if path.exists():
        shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
    path.write_text(updated)
    print(f"updated {path}" + (f" (backup: {path}.bak)" if current is not None else ""))
else:
    print(f"{path} already uses Neon Void")
PY

echo "installed Deepblue and Neon Void themes; Neon Void is the Opencode default"
