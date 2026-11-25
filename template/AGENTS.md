# Codex 执行入口 · 《Genius Makers》章节亲历式 3D 体验（通用版）

你是这个章节项目的**编排者**。先读本目录的 `INPUT.md`：它说明这次要做哪一章（或只定全书风格）、端口、工作区路径。然后按顺序读：`loop/LOOP.md`（唯一权威）→ `loop/RUBRICS.md` → `loop/PLANNING.md` → `loop/AMENDMENTS.md` → 工作区 `book/` 下的 `BOOK.md`、`PREFERENCES.md`、`SENSITIVITY.md` → `HANDOFF.md`（不存在就从 `LOOP.md` 附录A开始）。

本文件只说明 Codex 下的适配：独立会话、生图、长跑方式和注意事项。这里和 `LOOP.md` 冲突时，以 `LOOP.md` 为准。

---

## 必须记住的三条边界

1. **不读其他章节**：工作区 `chapters/` 下除本目录以外的任何文件都不读（宪法 C13）。
2. **全书风格控制**：`book-style/STYLE_CONTROL.md`、`style.tokens.json` 与用户的选择 `SELECTION.json` 永远只读；风格不由你选择，只实现选定的那一种。工具包 `kit/` 只有持有 `book-style/.building.json` 的 PK 阶段可以写，`LOCK.json` 存在后只读（宪法 C14、`LOOP.md` 5.K）。
3. **不碰工作区以外**：不修改工作区以外的任何文件，包括原书 PDF。

## 运行参数

全部来自 `INPUT.md`：`mode`、章节、页码、`workspace`、`pdf_path`、`page_map`、`selected_style`、`app_port`、`play_port`、`read_playbook`、`style_revision`。不同章节的端口不同，可以同时跑多个章节项目。

## 独立会话：实现 `tools/session.mjs`

输入是一个符合 `loop/schemas/session-request.schema.json` 的请求文件。实现要点：

1. 建 `rounds/rNNNN/sessions/<sid>/inbox/`，把白名单文件复制进去，写 `prompt.md`。
2. **每次都启动一个新进程，绝不使用 resume 或 fork**。基本形式（以 P0 实测为准）：

   ```sh
   codex exec --skip-git-repo-check -C <inbox> -s read-only \
     -i <图1> -i <图2> … \
     -o <sid>/last-message.txt \
     - < <sid>/prompt.md
   ```

   - 评审、比较、标注会话：`-s read-only`。
   - 盲测试玩会话：`inbox/` 里只放 `play` 这个转发脚本；用 `-s workspace-write -c sandbox_workspace_write.network_access=true`，让它能连 `127.0.0.1:<play_port>`。连不上就改用 `LOOP.md` 10.2 的回合制中转。
   - 如果 `codex exec --help` 列出 `--output-schema`，就传入对应 schema；没有就靠下一步校验。
3. 从最后一条消息中取出 JSON，按 schema 校验；不合格就附上校验错误、开一个新会话重试一次；仍不合格则丢弃并记录。
4. 实际命令、耗时、退出码写进 `<sid>/meta.json`。

**模型与推理档**：沿用本机 `~/.codex/config.toml`。规划、评审、比较、设计类会话用你能用的最强模型和最高推理档（本机支持时可用 `-m` 和 `-c model_reasoning_effort=…`）。P0 用 `codex exec --help` 加看图验证确认每个参数真的生效，把可用的完整命令写进 `state/capabilities.json`，之后只用记录过的命令。

**图片多的时候**：先用 `tools/contact-sheet.mjs` 拼成少量大图再附上。

## 生图：实现 `tools/imagegen.mjs`，并决定生图路线

1. **首选 Codex 内置 image_gen 工具**（风骇岛的概念板就是用它生成的）。无人值守时在子进程里调用：

   ```sh
   codex exec --skip-git-repo-check -C <输出目录> -s workspace-write \
     "使用内置 image_gen 工具生成：……（完整提示词）。保存为 <文件名>.png"
   ```

   有的版本需要在提示词开头写 `$imagegen` 才会触发内置工具。需要参考图时，先把它复制进输出目录（`-i` 不一定能把图交给 image_gen）。
2. 内置工具不可用、且本机设置了 `OPENAI_API_KEY` 时，可以改用官方图像 API。
3. **P0 判定路线**（`LOOP.md` 5.0）：真的生成一张测试图 → 检查是有效图片且尺寸 ≥ 1024 像素 → 交给一个新会话描述画面、与提示词逐项核对。全部通过记 `image_route: "image_first"`，走 `LOOP.md` 5.R 的“先图后模”；否则重试 3 次仍失败记 `spec_only`，直接按文字规格建模。实际命令、模型与失败原因写进 `state/capabilities.json`。每个阶段开始时重新探测一次。

生图只用来为**选定风格**画参考图（规格的图解），**永远不用来选择或更换风格**。提示词里不写真人姓名、不要求像任何人。所有提示词全文保存到 `prompts.md`（章节在 `design/concept/`，PK 在 `book-style/reference/approved/`）。参考图要先经过 `LOOP.md` 5.R 的审图才能作为建模目标；评审结论以实机渲染为准。

## 长跑方式

**A. 终端交互**：在本目录运行 `codex`，粘贴 `START.md` 里的启动 prompt。P0 需要联网安装依赖（Playwright、Chromium、Three.js），请在交互模式下完成。上下文被压缩后从 `HANDOFF.md` 继续。

**B. 终端无人值守**：P0 完成后运行 `tools/drive.sh`。它每轮启动一个新的编排者会话执行恰好一轮，直到 `state/loop-state.json` 的 `status` 变为 `finished`。

**C. Codex 桌面版**：把本目录添加为项目，**以本地方式（Local）运行，不要用 Worktree**（循环要写工作区的 `book-style/`、管理自己的 git 分支、启动本机浏览器）。新建线程粘贴启动 prompt 完成 P0；之后可以建一个本地执行的定时自动化，提示词用 `drive.sh` 里那一句，间隔 20–30 分钟。每轮开始的轮次锁（`LOOP.md` R0）保证上一轮没跑完时新触发的会话会直接退出。

权限（三种方式相同）：写本章项目目录（PK 阶段还要写工作区 `book-style/` 下的 `kit/`、`reference/approved/`、`reference/test-rooms/` 等，P8 要写 `playbook/` 里本章自己的文件）、启动本机 Chromium、访问 `127.0.0.1`、调用生图。如果沙箱挡住了这些，在 P0 记录现象，改用你跑风骇岛浏览器测试时用过的权限级别；不要放宽到工作区以外的写权限。`drive.sh` 的会话命令以 P0 实测为准，可以修改；改动记入 `LOG.md`。

## 异构评审（可选）

如果本机 `gemini --version` 或 `agy --version` 可用且已登录，可按 `LOOP.md` 8.5 让它担任比较团里的“轮换评委”：在 inbox 目录里用 `gemini -p`（或 `agy -p`）启动新进程，图片在提示词里以 `@文件名` 引用；先跑一次看图验证。不可用就跳过。

## 注意

- Codex 读取 `AGENTS.md` 有大小上限，所以规范放在 `loop/`，本文件保持简短。
- 可以开 Codex 子代理并行写代码，但**规划锦标赛、评审、比较、试玩、标注必须走 `tools/session.mjs` 的新进程**。独立性是这个循环成立的前提。
