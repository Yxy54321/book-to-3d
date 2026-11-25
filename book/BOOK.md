# 全书信息 · Genius Makers

所有章节项目共享、只读。页码一律是 PDF 物理页码（第几页 PDF 页面，不是印刷页码）。

## 书在哪里、页码对不对

- 本工作区**不包含**这本书。每个使用者用自己的 PDF：第一次运行 `./new-chapter.sh <章节> --pdf <路径>`（之后会记在本机的 `book/LOCAL_BOOK.json`），或者把 PDF 放进 `book/source/`。
- 下表的页码基于参考版本（一份 304 页的 PDF，指纹见 `chapter-map.json` 的 `reference_edition`）。你的 PDF 与参考版本不同（例如多了或少了封面页）时，`new-chapter.sh` 会自动运行 `book/verify_book.py`，按章名重新定位每章的正文页与注释页，生成本机使用的 `chapter-map.local.json`。也可以手动运行：`python3 book/verify_book.py <PDF 路径>`。
- `LOCAL_BOOK.json`、`chapter-map.local.json` 与 `book/source/` 里的 PDF 只属于你这台电脑，分享工作区前请移走。

## 基本信息

| 项 | 内容 |
|---|---|
| 书名 | Genius Makers: The Mavericks Who Brought AI to Google, Facebook, and the World |
| 作者 | Cade Metz（Dutton, 2021） |
| 结构 | 序章 + 21 章，分四部分 |
| 时间跨度 | 1950 年代（感知机）到 2020 年前后（书末时间线止于 2020） |
| 性质 | 非虚构叙事。作者在注释开头说明：全书基于四百多人的访谈，以及公司与个人文件、邮件；每个场景与重要细节至少有两个来源佐证 |

## 章节表（参考版本页码）

| id | 章名 | 题词 | 正文页 | 注释页 | 部分 |
|---|---|---|---|---|---|
| `prologue` | PROLOGUE · THE MAN WHO DIDN’T SIT DOWN | December 2012 | 9–17 | 260–260 | — |
| `1` | GENESIS | “Frankenstein Monster Designed by Navy That Thinks.” | 19–28 | 260–262 | PART ONE |
| `2` | PROMISE | “Old ideas are new.” | 29–42 | 262–263 | PART ONE |
| `3` | REJECTION | “I was definitely thinking I was right the whole time.” | 43–58 | 263–263 | PART ONE |
| `4` | BREAKTHROUGH | “Do what you want at Google—not what Google wants you to do.” | 59–69 | 264–264 | PART ONE |
| `5` | TESTAMENT | “The speed of light in a vacuum used to be about 35 mph. Then Jeff Dean spent a weekend optimizing physics.” | 70–84 | 264–265 | PART ONE |
| `6` | AMBITION | “Let’s really go big.” | 85–98 | 265–266 | PART ONE |
| `7` | RIVALRY | “Hello, this is Mark, from Facebook.” | 100–110 | 266–266 | PART TWO |
| `8` | HYPE | “Success is guaranteed.’’ | 111–124 | 267–268 | PART TWO |
| `9` | ANTI-HYPE | “He could produce something evil by accident.” | 125–136 | 268–270 | PART TWO |
| `10` | EXPLOSION | “He ran AlphaGo like Oppenheimer ran the Manhattan Project.” | 137–145 | 270–271 | PART TWO |
| `11` | EXPANSION | “George wiped out the whole field without even knowing its name.” | 146–153 | 271–272 | PART TWO |
| `12` | DREAMLAND | “It is not that people at Google drink different waters.” | 154–163 | 272–273 | PART TWO |
| `13` | DECEIT | “Oh, you can actually make photo-realistic faces.” | 165–172 | 273–274 | PART THREE |
| `14` | HUBRIS | “I knew when I gave the speech that the Chinese were coming.” | 173–183 | 274–275 | PART THREE |
| `15` | BIGOTRY | “Google Photos, y’all fucked up. My friend is not a gorilla.” | 184–191 | 275–276 | PART THREE |
| `16` | WEAPONIZATION | “You probably heard Elon Musk and his comment about AI causing WW3.” | 192–200 | 276–277 | PART THREE |
| `17` | IMPOTENCE | “There are people in Russia whose job it is to try to exploit our systems. So this is an arms race, right?” | 201–208 | 277–278 | PART THREE |
| `18` | DEBATE | “However long the rapid progress continues, Gary will still argue it is about to end.” | 210–219 | 278–279 | PART FOUR |
| `19` | AUTOMATION | “If the room looked like things had gone crazy, we were on the right track.” | 220–227 | 279–280 | PART FOUR |
| `20` | RELIGION | “My goal is to successfully create broadly beneficial AGI. I also understand this sounds ridiculous.” | 228–240 | 280–281 | PART FOUR |
| `21` | X FACTOR | “History is going to repeat itself, I think.” | 241–247 | 281–281 | PART FOUR |

部分标题页（不属于任何章节正文）：PART ONE 第18页；PART TWO 第99页；PART THREE 第164页；PART FOUR 第209页。注释页按 “PROLOGUE: …” / “CHAPTER N: TITLE” 小标题分段，相邻章节会共用一页，抽取时按小标题切分。

## 全书参考资料（参考版本页码；每章规划都可以用）

| 资料 | 页码 | 用途 |
|---|---|---|
| TIMELINE | 250–253 | 核对年份与先后 |
| THE PLAYERS | 254–259 | 人物身份、所属机构（只作身份核对，外貌与言行以正文为准） |
| NOTES | 260–281 | 每章的来源说明；考据时优先从这里找原始来源 |
| INDEX | 282–304 | 查同一人物、机构、概念在其他章节的出现（只用于了解上下文，不读取其他章节项目的产物） |

## 全书立场

正文是主叙事来源。外部资料与正文冲突时，体验以正文为准，分歧放到 L2 出处层说明。书中大多数人物仍然在世，涉及大量真实公司；处理方式见 `SENSITIVITY.md`。
