#!/usr/bin/env bash
# 创建一个章节项目（或风格工具包项目）。
# 用法：
#   ./new-chapter.sh 2                  第2章（可写 1–21）
#   ./new-chapter.sh prologue           序章（也可写 0）
#   ./new-chapter.sh style              只做风格工具包（建议在做任何章节之前先跑一次，可选）
#   ./new-chapter.sh style --revision   重新选择风格或改了 STYLE_CONTROL.md 之后重建工具包
#   任意命令后可加 --style archival|paper|editorial|miniature 直接指定风格（只在还没选定、或 --revision 时有效）
#   做章节时需要书的 PDF：第一次用 --pdf <路径> 指定（之后会记住），或把 PDF 放进 book/source/
set -eu
WS="$(cd "$(dirname "$0")" && pwd)"
if [ $# -lt 1 ]; then
  echo "用法：./new-chapter.sh <prologue|0|1-21|style> [--revision] [--style 名称] [--pdf 书的PDF路径]"; exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "需要 python3（macOS 可运行 xcode-select --install 安装命令行工具）"; exit 1
fi

TARGET="$1"; shift
REV="false"; STYLE=""; PDF=""
while [ $# -gt 0 ]; do
  case "$1" in
    --revision) REV="true" ;;
    --style|--skin) shift; STYLE="${1:-}"; [ $# -gt 0 ] || break ;;
    --pdf) shift; PDF="${1:-}"; [ $# -gt 0 ] || break ;;
    *) echo "不认识的参数：$1"; exit 1 ;;
  esac
  shift
done

SEL="$WS/book-style/SELECTION.json"
CURRENT=""
if [ -f "$SEL" ]; then
  CURRENT="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("style",""))' "$SEL")"
fi

need_choice="false"
if [ -z "$CURRENT" ]; then need_choice="true"; fi
if [ "$TARGET" = "style" ] && [ "$REV" = "true" ]; then need_choice="true"; fi

if [ "$need_choice" = "true" ] && [ -z "$STYLE" ]; then
  if [ ! -r /dev/tty ]; then echo "请用 --style 指定风格：archival | paper | editorial | miniature"; exit 1; fi
  echo ""
  if [ -n "$CURRENT" ]; then echo "当前全书风格：$CURRENT"; else echo "全书风格还没选定。选定后全书只做这一种（规格见 book-style/STYLE_CONTROL.md）："; fi
  echo "  1) archival   档案纪实：提炼自 Gemini 版第一章，锤纹钢柜、清漆木、黄铜、暖灯光池配冷窗光，轻微胶片感"
  echo "  2) paper      纸本世界：立体书纸艺模型，纸偶人物，年代靠印刷工艺区分"
  echo "  3) editorial  编辑插画：杂志插画立起来，有限色板、两段明暗、细描边、颗粒"
  echo "  4) miniature  桌面微缩模型：上色模型、展柜灯、移轴景深"
  printf "请输入 1-4："
  if ! read -r n < /dev/tty 2>/dev/null; then echo ""; echo "无法交互输入。请改用：./new-chapter.sh <章节或 style> --style archival|paper|editorial|miniature"; exit 1; fi
  case "$n" in 1) STYLE=archival ;; 2) STYLE=paper ;; 3) STYLE=editorial ;; 4) STYLE=miniature ;; *) echo "没有选择，已取消"; exit 1 ;; esac
fi

if [ -n "$STYLE" ]; then
  case "$STYLE" in archival|paper|editorial|miniature) ;; *) echo "风格只能是 archival | paper | editorial | miniature"; exit 1 ;; esac
  if [ -n "$CURRENT" ] && [ "$STYLE" != "$CURRENT" ] && ! { [ "$TARGET" = "style" ] && [ "$REV" = "true" ]; }; then
    echo "全书已经选定 $CURRENT。要更换风格，请用：./new-chapter.sh style --revision"; exit 1
  fi
fi

python3 - "$WS" "$TARGET" "$REV" "${STYLE:-$CURRENT}" "$PDF" <<'PY'
import json, os, shutil, sys, datetime, re, hashlib, subprocess, glob
ws, arg, rev, style, pdf_arg = sys.argv[1], sys.argv[2].strip().lower(), sys.argv[3] == "true", sys.argv[4], sys.argv[5]
book = os.path.join(ws, "book")

def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""): h.update(b)
    return h.hexdigest()

# ---- 找到书的 PDF：--pdf > book/LOCAL_BOOK.json > book/source/*.pdf ----
local_book = os.path.join(book, "LOCAL_BOOK.json")
pdf = None
if pdf_arg:
    pdf = os.path.abspath(os.path.expanduser(pdf_arg))
    if not os.path.exists(pdf): sys.exit(f"找不到 PDF：{pdf}")
elif os.path.exists(local_book):
    cand = json.load(open(local_book)).get("pdf_path")
    if cand and os.path.exists(cand): pdf = cand
if pdf is None:
    found = sorted(glob.glob(os.path.join(book, "source", "*.pdf")))
    if found: pdf = found[0]
if pdf is None and arg != "style":
    sys.exit("还不知道书的 PDF 在哪里。请加 --pdf <路径>（之后会记住），或把 PDF 放进 book/source/。")

cmap_path = os.path.join(book, "chapter-map.json")
if pdf:
    fp = sha(pdf)
    local_map = os.path.join(book, "chapter-map.local.json")
    def local_ok():
        return os.path.exists(local_map) and json.load(open(local_map, encoding="utf-8")).get("local_edition", {}).get("sha256") == fp
    if not local_ok():
        print("正在核对这份 PDF 的章节页码……")
        r = subprocess.run([sys.executable, os.path.join(book, "verify_book.py"), pdf], capture_output=True, text=True)
        out = r.stdout.strip()
        print(out.splitlines()[0] if out else r.stderr.strip())
        if r.returncode == 2:
            print("（无法自动核对，先用参考页码；章节开工时 P0 会再核对。）")
        elif r.returncode == 1:
            print("问题：" + out.split("问题：")[-1])
    if local_ok():
        cmap_path = local_map
    json.dump({"pdf_path": pdf, "sha256": fp, "map": os.path.basename(cmap_path),
               "date": datetime.date.today().isoformat()}, open(local_book, "w"), ensure_ascii=False, indent=2)
cmap = json.load(open(cmap_path, encoding="utf-8"))
today = datetime.date.today().isoformat()
names = {"archival": "档案纪实", "paper": "纸本世界", "editorial": "编辑插画", "miniature": "桌面微缩模型"}
sel_path = os.path.join(ws, "book-style", "SELECTION.json")
lock = os.path.join(ws, "book-style", "LOCK.json")

if arg == "style":
    if os.path.exists(lock) and not rev:
        sys.exit("风格工具包已经锁定（book-style/LOCK.json 存在）。要换风格或按新规格重建，请用：./new-chapter.sh style --revision")
    dirname = "style-revision" if rev else "style"
    n = 1
    while os.path.exists(os.path.join(ws, "chapters", dirname if n == 1 else f"{dirname}-{n}")):
        n += 1
    if n > 1: dirname = f"{dirname}-{n}"
    info = {"mode": "style", "style_revision": rev, "chapter_id": None,
            "app_port": 4391 if rev else 4390, "play_port": 4491 if rev else 4490}
    label = "风格工具包" + ("改版" if rev else "")
    info["title"] = label
else:
    if arg in ("0", "00", "prologue"): arg = "prologue"
    else: arg = arg.lstrip("0") or "0"
    found = [c for c in cmap["chapters"] if c["id"] == arg]
    if not found:
        sys.exit("找不到这一章。可用：prologue（或0）、1–21、style")
    c = found[0]
    slug = re.sub(r"[^a-z0-9]+", "-", c["title"].lower()).strip("-")
    dirname = f"ch{c['number']:02d}-{slug}"
    info = {"mode": "chapter", "style_revision": False, "chapter_id": c["id"], "chapter_number": c["number"],
            "title": c["title"], "subtitle": c.get("subtitle"), "epigraph": c.get("epigraph") or c.get("date_line"),
            "part": c.get("part"), "body_pages": c["body_pages"], "notes_pages": c["notes_pages"],
            "next_chapter_first_page": c.get("next_chapter_first_page"),
            "app_port": 4300 + c["number"], "play_port": 4400 + c["number"]}
    label = "序章" if c["id"] == "prologue" else f"第 {c['number']} 章 {c['title']}"

dest = os.path.join(ws, "chapters", dirname)
if os.path.exists(dest):
    sys.exit(f"{dest} 已存在。要重做，请先把旧文件夹改名或移走。")

# 写入或更新风格选择（只在用户选择时发生）
old = json.load(open(sel_path)) if os.path.exists(sel_path) else None
if old is None or (arg == "style" and rev and old.get("style") != style):
    sv = json.load(open(os.path.join(ws, "book-style", "style.tokens.json"), encoding="utf-8")).get("version")
    json.dump({"style": style, "chosen_by": "user", "date": today, "style_control_version": sv,
               "previous": old}, open(sel_path, "w"), ensure_ascii=False, indent=2)
    print(f"已记录全书风格：{style}（{names[style]}）→ book-style/SELECTION.json")

shutil.copytree(os.path.join(ws, "template"), dest)
info.update({"selected_style": style, "workspace": ws, "pdf_path": pdf, "page_map": os.path.relpath(cmap_path, ws), "project_dir": dest,
             "read_playbook": True, "created": today})

with open(os.path.join(dest, "INPUT.md"), "w", encoding="utf-8") as f:
    f.write(f"# 本次输入：{label}\n\n由 `new-chapter.sh` 于 {today} 生成。编排者以下面的 JSON 为准。\n\n```json\n")
    f.write(json.dumps(info, ensure_ascii=False, indent=2))
    f.write("\n```\n\n- 页码是这份 PDF 的物理页码，来自 `" + info["page_map"] + "`；P0 会再核对一次章节边界。\n"
            f"- 全书风格：`{style}`（{names[style]}），以 `book-style/SELECTION.json` 为准，循环不能更改。\n"
            "- `read_playbook`：是否读取工作区 `playbook/` 中其他项目留下的流程经验（只含流程，不含章节内容）。想让本章完全独立，就改成 `false`。\n"
            f"- 体验服务：http://127.0.0.1:{info['app_port']} ；试玩服务端口 {info['play_port']}。\n")

stylenote = f"全书风格已选定为 {style}（{names[style]}），见 book-style/SELECTION.json；规格在 book-style/STYLE_CONTROL.md。不要选择或更换风格。"
if info["mode"] == "chapter":
    task = f"本次要做的是《Genius Makers》{label}"
    flow = ("然后从 loop/LOOP.md 附录A开始执行：先完成 P0（能力自检——包括判定生图路线 image_first 或 spec_only——、安装依赖、按 INPUT.md 中的 pdf_path 与 page_map 抽取并核对本章正文与注释、搭好 tools/ 工具链，把实测可用的命令写进 state/capabilities.json；P0 需要联网，请在这个会话里完成）；"
            "再进入 P1 章节规划——按 loop/PLANNING.md 把这一章读透，做出规划、派生宪法、学习目标与机制测试计划；"
            "之后按 LOOP.md 第6节逐轮推进 P2 及以后各阶段。" + stylenote + "风格工具包还没锁定时，按 LOOP.md 5.K 处理；有生图能力时按 5.R 先图后模。")
else:
    task = "本次只做风格工具包" + ("（改版）" if rev else "") + "（mode=style）"
    flow = ("然后从 loop/LOOP.md 附录A开始执行：先完成 P0（能力自检——包括判定生图路线 image_first 或 spec_only——、安装依赖、搭好工具链；P0 需要联网，请在这个会话里完成），"
            "再执行 LOOP.md 5.K 的 PK 阶段：只实现选定的这一种风格。有生图能力时按 5.R 先为 SETTINGS_ATLAS.md 的 T1–T8 生成并审过参考图、再按图建模；没有就直接按文字规格建模。测试场景经独立评审后锁定。"
            + stylenote + "规格有缺口就按风格控制第10节处理并写进 OPEN_QUESTIONS.md。")

prompt = f"""你是这个项目的编排者。请先读本目录的 INPUT.md（{task}），再读 AGENTS.md，并按其中的顺序读 loop/ 下的规范和工作区 book/、book-style/ 下的全书文件。

{flow}

不要停下来问我。整个过程全自动、预算无上限；唯一的停止规则是 LOOP.md 第7节：连续多轮无进展就结束当前阶段、进入下一阶段，打磨阶段停滞后进入终审交付。每轮开始先按 LOOP.md R0 取得轮次锁。

边界：不要读取工作区 chapters/ 下其他项目的任何文件；不要修改 book-style/ 下的风格控制、风格选择与已锁定的工具包；不要修改工作区以外的任何文件，包括原书 PDF。每轮结束都把状态写回 state/、HANDOFF.md、LOG.md、progress.html。

如果你判断 P0 之后改用无人值守长跑更稳（每轮一个新会话），先按实测修好 tools/drive.sh 里的命令，在 HANDOFF.md 写明，然后用一句话告诉我怎么运行它。"""

with open(os.path.join(dest, "START.md"), "w", encoding="utf-8") as f:
    f.write(f"# 启动说明 · {label}（风格：{names[style]}）\n\n把下面这段 prompt 整段粘贴给 Codex（终端里运行 `codex`，或在 Codex 桌面版里把本文件夹添加为项目、以本地方式新建线程）：\n\n```\n" + prompt + "\n```\n\n"
            f"看进度：`HANDOFF.md`、`progress.html`；体验当前最好的版本：在本文件夹运行 `npm start`，打开 http://127.0.0.1:{info['app_port']} ；想插话：写一个 `.md` 放进 `feedback/`。\n")

print(f"已创建：{dest}")
print(f"下一步：把这个文件夹交给 Codex，粘贴 START.md 里的启动 prompt。")
PY
