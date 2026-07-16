# codex-touchbar-usage

Show Codex weekly usage on the MacBook Touch Bar through MTMR.

Example output:

```text
1w 25% ━━━─────── ↻07/20 09:49
```

## What It Does

- Reads Codex account rate limits through `codex app-server`.
- Shows weekly used percentage, a 10-segment progress rail, and reset time.
- Refreshes from MTMR every 60 seconds.
- Saves the latest successful result under `~/Library/Caches/CodexTouchBar/usage.json`.
- Shows cached data with a `⚠` marker and cache age when the RPC call fails.
- Shows `Codex RPC --` only when the RPC fails and no cache is available.
- Does not send a prompt or start a model run.

## Why App Server RPC

This project uses the Codex app-server protocol:

```json
{"id":2,"method":"account/rateLimits/read","params":null}
```

That is better than parsing local session logs because it reflects the account-level usage snapshot and is less tied to activity on one machine.

This project intentionally does not call `/status`. `/status` is an interactive Codex slash command, not a stable non-interactive CLI command.

## Requirements

- macOS with Touch Bar
- [MTMR](https://github.com/Toxblh/MTMR)
- ChatGPT.app with the bundled Codex binary
- Logged in Codex account
- Python 3

## Install

```bash
git clone git@github.com:windrlee/codex-touchbar-usage.git
cd codex-touchbar-usage
./install.sh
```

Test:

```bash
/usr/local/bin/codex-touchbar-usage
```

Expected:

```text
1w 25% ━━━─────── ↻07/20 09:49
```

## MTMR Setup

Open:

```text
~/Library/Application Support/MTMR/items.json
```

Add the item from:

```text
examples/mtmr-item.json
```

Minimal item:

```json
{
  "type": "shellScriptTitledButton",
  "refreshInterval": 60,
  "source": {
    "inline": "/usr/local/bin/codex-touchbar-usage 2>/dev/null || echo 'Codex RPC --'"
  },
  "width": 370,
  "align": "left",
  "bordered": false
}
```

Restart MTMR:

```bash
killall MTMR
open /Applications/MTMR.app
```

## Format

```text
1w 25% ━━━─────── ↻07/20 09:49
```

- `1w`: weekly window.
- `25%`: used percentage.
- `━━━───────`: 10-segment usage rail.
- `↻07/20 09:49`: reset time.

## Failure Behavior

If `codex app-server` is unavailable or the RPC call times out, the script uses
the last successful result and marks it as cached:

```text
⚠ 1w 25% ━━━─────── ↻07/20 09:49 ·2m
```

The cache is stored at:

```text
~/Library/Caches/CodexTouchBar/usage.json
```

If no successful result has ever been cached, the script prints:

```text
Codex RPC --
```

It does not fall back to local session logs. The cache is only used when the
official RPC call fails, and the `⚠` marker prevents it from looking live.

## References

- [MTMR](https://github.com/Toxblh/MTMR)
- [CodexBar](https://github.com/steipete/CodexBar)
- [CodexBar Codex provider notes](https://github.com/steipete/CodexBar/blob/main/docs/codex.md)
- [CodexBar CLI notes](https://github.com/steipete/CodexBar/blob/main/docs/cli.md)
- Codex app-server schema can be generated locally:

```bash
codex app-server generate-json-schema --out /tmp/codex-appserver-schema
```

Useful methods observed in the schema:

- `account/read`
- `account/rateLimits/read`
- `account/rateLimits/updated`
- `account/usage/read`

## Development

Run tests:

```bash
python3 -m unittest -q tests/test_codex_touchbar_usage.py
```

Run the script:

```bash
python3 scripts/codex-touchbar-usage
```

## Notes

The Codex app-server API is currently experimental. The script keeps the integration small and fails closed with `Codex RPC --` if the RPC shape changes.
