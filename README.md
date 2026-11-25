# Book to 3D

A Codex harness for adapting chapters of *Genius Makers* into interactive 3D experiences. It provides chapter planning, a shared visual style, and a loop for building, playtesting, and reviewing each scene.

## Quick start

Open this repository as a local project in Codex. Tell it which chapter to build, which visual style to use, and where to find your copy of the book.

For a terminal setup, run these commands from the repository root.

```sh
./new-chapter.sh 2 --style archival --pdf ~/Downloads/genius-makers.pdf
cd chapters/ch02-promise
codex
```

Paste the prompt from `START.md` into Codex. Follow progress in `HANDOFF.md` and `progress.html` inside the chapter folder.

Requires Codex, Node.js 20+, Python 3, Git, and either `pdftotext` or `pypdf`.
