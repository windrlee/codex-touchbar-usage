# Codex Touch Bar 用量显示

[English README](README.md)

在 macOS Touch Bar 上通过 [MTMR](https://github.com/Toxblh/MTMR) 显示 Codex 账户周用量、进度条和重置时间。

示例：

```text
1w 25% ━━━─────── ↻07/20 09:49
```

## 工作方式

脚本通过 Codex app-server RPC 获取账户级用量：

```json
{"id":2,"method":"account/rateLimits/read","params":null}
```

它不会发送提示词，也不会启动模型任务，因此不会额外消耗模型 Token。当前只显示 Codex 的周额度：

- `1w`：周用量窗口。
- `25%`：已使用百分比。
- `━━━───────`：十段式进度条，每段约代表 10%。
- `↻07/20 09:49`：下次重置时间。

MTMR 每 60 秒重新执行一次脚本。

## 环境要求

- 带 Touch Bar 的 Mac。
- macOS 已安装 [MTMR](https://github.com/Toxblh/MTMR)。
- 已安装 ChatGPT.app，并完成 Codex 登录。
- Python 3。

脚本使用 ChatGPT.app 内置的 Codex 二进制，不依赖旧的 `/usr/local/bin/codex` Node 启动脚本。

## 安装

```bash
git clone git@github.com:windrlee/codex-touchbar-usage.git
cd codex-touchbar-usage
./install.sh
```

安装后测试：

```bash
/usr/local/bin/codex-touchbar-usage
```

正常输出类似：

```text
1w 25% ━━━─────── ↻07/20 09:49
```

## 配置 MTMR

打开：

```text
~/Library/Application Support/MTMR/items.json
```

把 [examples/mtmr-item.json](examples/mtmr-item.json) 中的项目加入 `items.json`。该示例包含：

- 60 秒自动刷新。
- 370 宽度的左对齐文本区域。
- 单击打开 ChatGPT.app。

修改后重启 MTMR：

```bash
killall MTMR
open /Applications/MTMR.app
```

如果只需要最小配置：

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

## RPC 失败时的缓存

RPC 成功时，脚本会保存最近一次成功结果：

```text
~/Library/Caches/CodexTouchBar/usage.json
```

RPC 暂时失败时，脚本会使用最近一次成功结果，并增加 `⚠` 标记和缓存年龄：

```text
⚠ 1w 25% ━━━─────── ↻07/20 09:49 ·2m
```

这表示当前显示的是约 2 分钟前的缓存数据，不应视为实时状态。如果从未成功获取过数据，则显示：

```text
Codex RPC --
```

脚本不会回退到本地 session 日志，避免跨设备使用或旧日志导致显示过期数据。

## 常见问题

### 显示 `Codex RPC --`

先手动运行：

```bash
/usr/local/bin/codex-touchbar-usage
```

如果仍失败，确认 ChatGPT.app 已安装并且 Codex 已完成登录。也可以确认内置二进制存在：

```bash
test -x /Applications/ChatGPT.app/Contents/Resources/codex && echo OK
```

### 数据没有立即变化

MTMR 默认每 60 秒刷新一次。RPC 失败时还会暂时显示缓存，并带有 `⚠` 标记。等待下一次刷新，或手动重新运行脚本确认接口状态。

### 显示旧数据是否会消耗 Token

不会。读取 app-server 的账户额度和读取本地缓存都不会发送模型请求。

## 开发与测试

运行测试：

```bash
python3 -m unittest -q tests/test_codex_touchbar_usage.py
```

直接运行项目脚本：

```bash
python3 scripts/codex-touchbar-usage
```

## 参考

- [MTMR](https://github.com/Toxblh/MTMR)
- [CodexBar](https://github.com/steipete/CodexBar)
- [CodexBar Codex provider 文档](https://github.com/steipete/CodexBar/blob/main/docs/codex.md)
- [CodexBar CLI 文档](https://github.com/steipete/CodexBar/blob/main/docs/cli.md)

本项目使用的 app-server 接口仍可能随 Codex 版本变化。接口异常时，脚本会优先显示明确的失败状态或带标记的缓存状态，不伪装成实时数据。
