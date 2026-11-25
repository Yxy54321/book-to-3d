# 工作区调度入口 · 《Genius Makers》章节亲历式 3D 体验（Codex）

> 如果你当前的工作目录已经是 `chapters/` 下的某个章节项目，忽略本文件，以那个目录里的 `AGENTS.md` 为准。

你在这个工作区的根目录。使用者通常只用一句话交代任务，例如：

- “用 archival 风格做第 2 章，书在 ~/Downloads/genius-makers.pdf”
- “先用纸本风格把风格工具包做了”
- “继续第 2 章”

你的工作是把这句话变成正确的准备动作，然后进入对应的章节项目，按那里的规范全自动地做下去。

## 1. 解析请求

| 要素 | 怎么确定 | 缺了怎么办 |
|---|---|---|
| 章节 | 序章（prologue / 0）或 1–21；也接受章名（如 PROMISE → 2，见 `book/BOOK.md`） | 问一次 |
| 风格 | `archival` 档案纪实、`paper` 纸本世界、`editorial` 编辑插画、`miniature` 桌面微缩模型（中文名也算） | `book-style/SELECTION.json` 已存在就用已选的；没有就问一次 |
| 书的 PDF | 使用者给的路径 | 依次看 `book/LOCAL_BOOK.json`、`book/source/*.pdf`；都没有就问一次 |

这几项是**开工前唯一允许的提问**。开工以后全自动，不再停下来问。

如果使用者说的风格和 `SELECTION.json` 里已选的不同：告诉他全书已经选定了哪一种，问他是要换（换就运行 `./new-chapter.sh style --revision --style <新风格>`，已做完的章节保留原风格），还是沿用已选的。

## 2. 准备

1. 检查环境：Node（≥ 20）、python3、git；抽取 PDF 文本需要 `pdftotext`（macOS：`brew install poppler`）或 pypdf（`python3 -m pip install --user pypdf`）。缺什么就装什么，需要批准时请求批准。
2. 运行创建脚本（路径加引号）：

   ```sh
   ./new-chapter.sh <章节> --style <风格> --pdf "<PDF 路径>"
   ./new-chapter.sh style --style <风格>          # 只做风格工具包时
   ```

   脚本会核对这份 PDF：与参考版本相同就直接用参考页码；不同就按章名重新定位，生成本机的 `book/chapter-map.local.json`。
3. 读脚本输出。如果它报告找不到某些章名页：使用者要做的那一章也找不到时，告诉使用者（PDF 可能不是这本书，或版本差异太大），停止；只是别的章找不到时，记录下来继续。
4. 对应的章节目录已经存在时，不要新建，按“继续”处理。

## 3. 开工

进入 `chapters/<目录>/`，**把它当作项目根**：打开其中的 `START.md`，把里面的 prompt 当作你接下来的指令执行（读 `INPUT.md`、`AGENTS.md`、`loop/` 规范，从 `loop/LOOP.md` 附录A开始）。之后：

- 所有相对路径都以章节目录为准；
- git 操作只在章节目录内进行（它有自己的仓库）；
- 章节目录里的 `AGENTS.md` 和 `loop/LOOP.md` 是那之后的权威。

“继续第 N 章”：进入已存在的章节目录，读 `HANDOFF.md`，接着执行下一轮。

## 4. 长跑

第一阶段（P0）完成后，用一句话告诉使用者两种长跑方式：

- 终端：`chapters/<目录>/tools/drive.sh`
- Codex 桌面版：新建一个本地执行的定时自动化（间隔 20–30 分钟），提示词：

  ```
  在 chapters/<目录>/ 中：读 INPUT.md、AGENTS.md 与 HANDOFF.md，严格执行 loop/LOOP.md 的下一轮（恰好一轮，R0–R8；若轮次锁被占用就直接退出），把所有状态写回文件后退出。
  ```

## 5. 边界

- 不修改 `book-style/` 下的风格控制与风格选择（只有使用者明确要求改版时，才用 `new-chapter.sh style --revision`）。
- 不修改工作区以外的任何文件，包括 PDF。
- 书的 PDF 与抽取出的文本只在本机使用，不放进任何会被分享的产物。
- 不同章节项目互不读取。
