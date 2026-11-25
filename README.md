# 《Genius Makers》章节亲历式 3D 体验 · 通用 RSI 循环（Codex 版）

把《Genius Makers》的任意一章做成可以亲历、可以交互的风格化 3D 体验。Codex 会先把这一章读透并做出规划，再一轮一轮地设计、制作、评审、改进，直到没有进展后交付。全自动，中途不需要你。

**这个工作区不包含书。** 每个使用者用自己的 PDF。

## 最简用法（Codex 桌面版）

1. 解压这个文件夹，放在任意位置。
2. 在 Codex 里把整个 `GeniusMakers-RSI-Codex` 文件夹添加为项目。运行方式选**本地（Local）**，不要选 Worktree；权限选允许改文件、运行命令、联网的那一档。
3. 新建线程，用一句话说清三件事——哪一章、什么风格、书在哪里：

   > 用 archival 风格做第 2 章，书在 ~/Downloads/genius-makers.pdf

   风格四选一：`archival` 档案纪实、`paper` 纸本世界、`editorial` 编辑插画、`miniature` 桌面微缩模型。全书只用一种，第一次说了之后，后面的章节就沿用它。

Codex 会自己完成后面的事：检查环境、核对你的 PDF（版本不同会按章名重新定位页码）、创建章节项目，然后开始做。第一阶段完成后，它会告诉你怎样设置定时自动化，让它一直跑下去。

想继续某一章，就说“继续第 2 章”。

## 在终端用

```sh
./new-chapter.sh 2 --style archival --pdf ~/Downloads/genius-makers.pdf
cd chapters/ch02-promise && codex      # 粘贴 START.md 里的 prompt
./tools/drive.sh                        # 第一阶段完成后，无人值守长跑
```

`--style` 只在第一次需要（不写会让你从菜单里选），`--pdf` 也只需第一次（之后会记住，或者把 PDF 放进 `book/source/`）。

## 看结果

都在章节文件夹（如 `chapters/ch02-promise/`）里：

| 想看 | 看哪里 |
|---|---|
| 做到哪一步 | `HANDOFF.md` |
| 每轮结果和画面变化 | 用浏览器打开 `progress.html` |
| 亲自玩当前最好的版本 | 在章节文件夹运行 `npm start`，打开 `INPUT.md` 里写的地址 |
| 插话 | 写一个 `.md` 放进 `feedback/`，下一轮会优先处理 |
| 做完了 | 出现 `FINAL_REPORT.md`；记得暂停这一章的定时自动化 |

## 需要的环境

Codex（已登录）、Node 20 以上、python3、git。抽取 PDF 文本需要 `pdftotext`（`brew install poppler`）或 pypdf（`python3 -m pip install --user pypdf`），缺了 Codex 会提示安装。能生图时会先出参考图再建模，不能生图就直接按文字规格建模，第一阶段的能力自检会自动判断。

## 文件夹里有什么

```
AGENTS.md          Codex 的调度入口（把你的一句话变成准备动作）
new-chapter.sh     创建章节项目
book/              页码表、页码核对脚本、全书默认偏好、敏感性指南
book-style/        四种风格的规格、你的选择、风格工具包
playbook/          各章留下的流程经验
template/          章节项目模板（含完整的循环规范 loop/）
chapters/          每章一个项目
```

## 需要知道的

- 全书默认（`book/PREFERENCES.md`）：每幕以一个真实在场者的身份体验；知识分层；书里的机制必须真实运行；全自动、预算无上限、连续多轮无进展才进入下一阶段；一次一章、各章互不读取；中文界面，原话保留英文附译文；桌面浏览器。
- 书中多数人物仍然在世。`book/SENSITIVITY.md` 列了十二类处理原则，每章都要逐类扫描。
- 循环里的“试玩”是 AI 试玩员，报告里会和真人体验明确区分。
- **分享工作区前**，移走 `book/source/` 里的 PDF，以及 `book/LOCAL_BOOK.json`、`book/chapter-map.local.json`（它们只属于你这台电脑）。
