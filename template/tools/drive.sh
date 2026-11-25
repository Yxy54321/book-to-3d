#!/usr/bin/env bash
# 无人值守驱动（Codex）：每轮启动一个新的编排者会话，执行恰好一轮。
# 先在交互模式完成 P0（state/loop-state.json 存在后再用）。会话命令以 P0 实测为准，可修改。
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/logs"
CODEX_FLAGS="${CODEX_FLAGS:---full-auto}"
PROMPT="读 INPUT.md、AGENTS.md 与 HANDOFF.md。严格执行 loop/LOOP.md 的下一轮（恰好一轮，R0–R8；若轮次锁被占用就直接退出），把所有状态写回文件后退出。"

status() {
  python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("status",""))' \
    "$ROOT/state/loop-state.json" 2>/dev/null || echo missing
}

fails=0
while true; do
  s="$(status)"
  if [ "$s" = "finished" ]; then echo "循环已结束，见 FINAL_REPORT.md"; break; fi
  if [ "$s" = "missing" ]; then echo "没有 state/loop-state.json：请先在交互模式完成 P0"; exit 1; fi
  ts="$(date +%Y%m%d-%H%M%S)"
  echo "[$ts] 开始新一轮（status=$s）" | tee -a "$ROOT/logs/drive-status.txt"
  # shellcheck disable=SC2086
  codex exec --skip-git-repo-check -C "$ROOT" $CODEX_FLAGS "$PROMPT" > "$ROOT/logs/drive-$ts.log" 2>&1
  code=$?
  if [ $code -ne 0 ]; then
    fails=$((fails+1))
    wait_s=$(( 60 * fails )); [ $wait_s -gt 1800 ] && wait_s=1800
    echo "[$ts] 会话异常退出 code=$code，连续 $fails 次，${wait_s}s 后重试" | tee -a "$ROOT/logs/drive-status.txt"
    sleep "$wait_s"
  else
    fails=0
    sleep 5
  fi
done
