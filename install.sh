#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="/usr/local/bin/codex-touchbar-usage"

install -m 0755 "$repo_dir/scripts/codex-touchbar-usage" "$target"

echo "Installed: $target"
echo "Test it with: $target"
