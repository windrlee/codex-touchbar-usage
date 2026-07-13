import importlib.machinery
import importlib.util
import io
from contextlib import redirect_stdout
from pathlib import Path
import unittest
from unittest import mock


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "scripts" / "codex-touchbar-usage"


def load_usage_module():
    loader = importlib.machinery.SourceFileLoader("codex_touchbar_usage", str(SCRIPT_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class ProgressBarTest(unittest.TestCase):
    def test_renders_used_percent_as_ten_segment_line_rail(self):
        usage = load_usage_module()

        self.assertEqual(usage.fmt_usage(0), "0% ──────────")
        self.assertEqual(usage.fmt_usage(8), "8% ━─────────")
        self.assertEqual(usage.fmt_usage(20), "20% ━━────────")
        self.assertEqual(usage.fmt_usage(40), "40% ━━━━──────")
        self.assertEqual(usage.fmt_usage(60), "60% ━━━━━━────")
        self.assertEqual(usage.fmt_usage(100), "100% ━━━━━━━━━━")

    def test_missing_percent_has_no_misleading_bar(self):
        usage = load_usage_module()

        self.assertEqual(usage.fmt_usage(None), "--")

    def test_title_displays_only_the_weekly_limit(self):
        usage = load_usage_module()

        self.assertEqual(
            usage.fmt_title("0% ──────────", "07/20"),
            "1w 0% ────────── ↻07/20",
        )

    def test_normalizes_codex_rpc_rate_limits(self):
        usage = load_usage_module()

        payload = usage.normalize_rpc_rate_limits(
            {
                "rateLimits": {
                    "limitId": "codex",
                    "primary": {
                        "usedPercent": 21,
                        "windowDurationMins": 10080,
                        "resetsAt": 1784512186,
                    },
                    "secondary": None,
                },
                "rateLimitsByLimitId": {
                    "codex_bengalfox": {
                        "limitId": "codex_bengalfox",
                        "primary": {"usedPercent": 0, "resetsAt": 1784531955},
                    },
                    "codex": {
                        "limitId": "codex",
                        "primary": {
                            "usedPercent": 21,
                            "windowDurationMins": 10080,
                            "resetsAt": 1784512186,
                        },
                    },
                },
            }
        )

        self.assertEqual(
            payload,
            {
                "rate_limits": {
                    "primary": {
                        "used_percent": 21,
                        "resets_at": 1784512186,
                    }
                }
            },
        )

    def test_main_shows_rpc_failure_without_local_log_fallback(self):
        usage = load_usage_module()

        with mock.patch.object(usage, "fetch_rate_limits_from_codex_rpc", return_value=None):
            output = io.StringIO()
            with redirect_stdout(output):
                exit_code = usage.main()

        self.assertEqual(exit_code, 0)
        self.assertEqual(output.getvalue().strip(), "Codex RPC --")


if __name__ == "__main__":
    unittest.main()
