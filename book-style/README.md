# 全书风格（book-style）

| 文件 | 谁写 | 循环能否修改 |
|---|---|---|
| `STYLE_CONTROL.md` | 用户与 plan agent 审定：四种可选风格的完整规格 + 所有风格共用的规则 | **不能** |
| `style.tokens.json` | 同上（机器可读版本） | **不能** |
| `SELECTION.json` | 你选定的风格，由 `new-chapter.sh` 写入 | **不能** |
| `SETTINGS_ATLAS.md` | plan agent 的全书场景普查 | 不能（章节把新场景写进自己的 `style-extension.md`） |
| `reference/archival-from-gemini/` | 从 Gemini 版第一章选出的参考图（archival 风格） | 不能 |
| `reference/approved/` | PK 阶段生成并审过的测试场景参考图（有生图能力时） | 只有持有构建锁的 PK 阶段能写 |
| `kit/` | PK 阶段按选定风格实现的风格工具包 | 同上 |
| `reference/test-rooms/` | PK 阶段渲染的 8 个测试场景 | 同上 |
| `IMPLEMENTATION_NOTES.md` | PK 阶段记录实现细节 | 同上 |
| `OPEN_QUESTIONS.md` | 任何项目遇到风格控制没覆盖的情况时追加 | 只能追加 |
| `LOCK.json` | PK 阶段完成后写入 | 锁定后只读 |
| `.building.json` | PK 阶段进行中的构建锁 | — |

## 流程

1. 四种风格的规格已经写好（`STYLE_CONTROL.md`）。第一次运行 `./new-chapter.sh` 时你选定一种，写进 `SELECTION.json`。**全书只实现、只打磨这一种。**
2. 第一次需要时（`./new-chapter.sh style` 专门跑一次，或某一章在 P2 之后发现没有 `LOCK.json`），PK 阶段按选定风格实现 `kit/`：有生图能力就先为 8 个测试场景生成参考图、审过后按图建模；没有就直接按文字规格建模。测试场景经独立评审通过后写入 `LOCK.json`。
3. 之后每一章把 `kit/` 复制进自己的项目，只在选定风格之内工作。

## 换风格或改规格

运行 `./new-chapter.sh style --revision`：可以重新选择风格，也可以在此之前编辑 `STYLE_CONTROL.md` 与 `style.tokens.json`（把版本号改为 v1.1 等）。它会重建工具包。已经做完的章节继续使用它们当时复制的版本。

`OPEN_QUESTIONS.md` 里积累的问题，是你改规格时最值得先看的地方。
