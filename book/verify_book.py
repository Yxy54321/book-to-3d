#!/usr/bin/env python3
"""核对一本《Genius Makers》PDF，并生成本机使用的章节页码表 book/chapter-map.local.json。

用法：python3 book/verify_book.py <PDF 路径> [--detect]

- 先比较文件指纹：与参考版本完全相同时，直接沿用 chapter-map.json 的页码（仍抽查章名）。
- 不同版本（或加 --detect）时，按章节标题重新定位每章的正文页、注释页与全书参考资料页。
- 文本抽取优先用 pdftotext（poppler），没有时用 Python 的 pypdf；两者都没有会给出安装提示。
退出码：0 = 全部章节定位成功；1 = 有章节没找到（详见输出与 problems 字段）；2 = 无法抽取文本。
"""
import hashlib, json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def extract_pages(pdf):
    if shutil.which("pdftotext"):
        out = subprocess.run(["pdftotext", "-layout", pdf, "-"], capture_output=True, text=True, errors="replace")
        if out.returncode == 0:
            pages = out.stdout.split("\f")
            if pages and not pages[-1].strip():
                pages = pages[:-1]
            return pages, "pdftotext"
    try:
        from pypdf import PdfReader  # type: ignore
        r = PdfReader(pdf)
        return [(p.extract_text() or "") for p in r.pages], "pypdf"
    except ImportError:
        pass
    sys.stderr.write("无法抽取 PDF 文本：请安装 poppler（macOS: brew install poppler）或 pypdf（python3 -m pip install --user pypdf）。\n")
    sys.exit(2)


def norm(s):
    s = s.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
    return re.sub(r"\s+", " ", s).strip().upper()


def head_lines(text, n=6):
    return [norm(l) for l in text.splitlines() if l.strip()][:n]


def is_chapter_start(text, c):
    h = head_lines(text)
    if c["id"] == "prologue":  # 允许首字下沉的单个字母出现在最前面；排除目录页
        return "PROLOGUE" in h[:3] and "CONTENTS" not in h[:3] and any("THE MAN WHO" in x for x in h[:5])
    title = norm(c["title"])
    return str(c["number"]) in h[:3] and title in h[:4]


def is_part_page(text):
    h = head_lines(text, 2)
    return bool(h) and h[0].startswith("PART ")


def main():
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(2)
    pdf = os.path.abspath(os.path.expanduser(sys.argv[1]))
    force_detect = "--detect" in sys.argv[2:]
    if not os.path.exists(pdf):
        sys.stderr.write(f"找不到文件：{pdf}\n"); sys.exit(2)
    ref = json.load(open(os.path.join(HERE, "chapter-map.json"), encoding="utf-8"))
    pages, tool = extract_pages(pdf)
    fp = sha256(pdf)
    same = (fp == ref.get("reference_edition", {}).get("sha256")) and not force_detect
    out = json.loads(json.dumps(ref))
    out["pdf_path"] = pdf
    problems = []

    if same:
        for c in out["chapters"]:
            s = c["body_pages"][0]
            if not (1 <= s <= len(pages)) or not is_chapter_start(pages[s - 1], c):
                problems.append(f"{c['id']}：第{s}页没有找到章名 {c['title']}")
    else:
        # 1) 定位各章起始页（保持顺序）
        starts, cursor = {}, 0
        for c in out["chapters"]:
            found = None
            for i in range(cursor, len(pages)):
                if is_chapter_start(pages[i], c):
                    found = i + 1; break
            if found is None:
                problems.append(f"{c['id']}：没有找到章名页 {c['title']}")
            else:
                starts[c["id"]] = found; cursor = found
        # 2) 全书参考资料
        refs = {}
        for key, label in [("acknowledgments", "ACKNOWLEDGMENTS"), ("timeline", "TIMELINE"),
                           ("the_players", "THE PLAYERS"), ("notes", "NOTES"), ("index", "INDEX")]:
            for i in range(cursor, len(pages)):
                if label in head_lines(pages[i], 3):
                    refs[key] = i + 1; break
        order = [k for k in ["acknowledgments", "timeline", "the_players", "notes", "index"] if k in refs]
        br = {}
        for j, k in enumerate(order):
            end = (refs[order[j + 1]] - 1) if j + 1 < len(order) else len(pages)
            br[k] = [refs[k], end]
        out["book_references"] = {**{"contents": ref["book_references"].get("contents")}, **br}
        # 3) 正文页范围（排除部分标题页）
        ids = [c["id"] for c in out["chapters"]]
        first_ref = min(refs.values()) if refs else len(pages) + 1
        for k, c in enumerate(out["chapters"]):
            if c["id"] not in starts:
                continue
            s = starts[c["id"]]
            nxt = next((starts[i] for i in ids[k + 1:] if i in starts), first_ref)
            e = nxt - 1
            while e > s and is_part_page(pages[e - 1]):
                e -= 1
            c["body_pages"] = [s, e]
            c["next_chapter_first_page"] = nxt if nxt != first_ref else None
        # 4) 注释页
        if "notes" in br:
            ns, ne = br["notes"]
            heads = []  # (页码, 该页第几个非空行, 标题)
            for i in range(ns - 1, ne):
                k = 0
                for l in pages[i].splitlines():
                    if not l.strip():
                        continue
                    L = norm(l)
                    if L.startswith("PROLOGUE:") or re.match(r"^CHAPTER \d+:", L):
                        heads.append((i + 1, k, L))
                    k += 1
            for c in out["chapters"]:
                key = "PROLOGUE:" if c["id"] == "prologue" else f"CHAPTER {c['number']}:"
                idx = [j for j, h in enumerate(heads) if h[2].startswith(key)]
                if not idx:
                    problems.append(f"{c['id']}：注释里没有找到 {key}"); continue
                j = idx[0]
                if j + 1 < len(heads):
                    np_, nk, _ = heads[j + 1]
                    end = np_ - 1 if (nk <= 2 and np_ > heads[j][0]) else np_
                else:
                    end = ne
                c["notes_pages"] = [heads[j][0], max(end, heads[j][0])]
        else:
            problems.append("没有找到 NOTES 部分")

    out["local_edition"] = {"sha256": fp, "pages": len(pages), "text_tool": tool,
                            "matches_reference": same, "verified": not problems, "problems": problems}
    dst = os.path.join(HERE, "chapter-map.local.json")
    json.dump(out, open(dst, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"{'与参考版本相同' if same else '与参考版本不同，已按章名重新定位'}；共 {len(pages)} 页；文本工具：{tool}")
    for c in out["chapters"]:
        print(f"  {c['id']:>8}  {c['title']:<14} 正文 {c['body_pages']}  注释 {c['notes_pages']}")
    if problems:
        print("问题："); [print("  - " + p) for p in problems]
        sys.exit(1)
    print(f"已写入 {dst}")


if __name__ == "__main__":
    main()
