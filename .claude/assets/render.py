#!/usr/bin/env python3
"""Render a blog draft to clean + (optionally) review HTML.

Usage (run from the drafts/ directory):
    python render.py <slug>                 # writes <slug>.html  (clean — Substack paste source)
    BLOG_REVIEW=1 python render.py <slug>   # also writes <slug>-review.html

Reads, relative to the current directory:
    <slug>.md            source of truth (the only file the author edits)
    revision-notes.md    per-round changelog  (review build only)
    review-snippet.html  comment-layer JS     (review build only)

Title comes from the first `# H1` in the markdown (falls back to the slug).

HARD INVARIANT: the clean build (<slug>.html) NEVER contains review tooling.
The script asserts this after writing and exits non-zero if it ever leaks.
"""
import os
import re
import sys
from pathlib import Path

try:
    import markdown
except ImportError:
    sys.exit(
        "Missing dependency: python-markdown.\n"
        "  Install with:  pip install markdown   (or: uv pip install markdown)"
    )

EXTENSIONS = ["tables", "fenced_code", "footnotes", "sane_lists", "nl2br"]

# Marker the clean build must never contain (the review toolbar's id).
REVIEW_MARKER = "cmt-bar"

CSS = """
  :root { color-scheme: light dark; }
  body {
    max-width: 720px; margin: 3rem auto; padding: 0 1.25rem;
    font: 18px/1.7 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #1a1a1a; background: #fff;
  }
  h1 { font-size: 2.1rem; line-height: 1.2; margin: 0 0 1.5rem; }
  h2 { font-size: 1.45rem; margin: 2.5rem 0 1rem; }
  h3 { font-size: 1.15rem; margin: 2rem 0 .75rem; }
  p, li { font-size: 1.06rem; }
  a { color: #1a5fb4; }
  strong { font-weight: 650; }
  blockquote {
    margin: 1.5rem 0; padding: .5rem 0 .5rem 1.25rem;
    border-left: 3px solid #d0d0d0; color: #444; font-style: italic;
  }
  code {
    font: .92em ui-monospace, SFMono-Regular, Menlo, monospace;
    background: #f3f3f3; padding: .12em .35em; border-radius: 4px;
  }
  pre { background: #f6f8fa; padding: 1rem; border-radius: 8px; overflow-x: auto; }
  pre code { background: none; padding: 0; }
  table { border-collapse: collapse; width: 100%; margin: 1.5rem 0; font-size: .98rem; }
  th, td { border: 1px solid #ddd; padding: .5rem .75rem; text-align: left; }
  th { background: #f6f6f6; }
  img { max-width: 100%; height: auto; }
  hr { border: none; border-top: 1px solid #e2e2e2; margin: 2.5rem 0; }
  .revision-banner {
    max-width: 720px; margin: 0 auto 2.5rem; padding: 1rem 1.25rem;
    background: #fff8e1; border: 1px solid #f0d27a; border-radius: 8px;
    font-size: .95rem;
  }
  .revision-banner h2 { margin: 0 0 .5rem; font-size: 1.05rem; }
  @media (prefers-color-scheme: dark) {
    body { color: #e6e6e6; background: #121212; }
    th { background: #1e1e1e; } th, td { border-color: #333; }
    code, pre { background: #1e1e1e; }
    blockquote { border-color: #444; color: #bbb; }
    .revision-banner { background: #2a2410; border-color: #5a4d1a; }
  }
"""

PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>{css}</style>
</head>
<body>
{banner}{body}
{review}</body>
</html>
"""


def extract_title(md_text, fallback):
    for line in md_text.splitlines():
        m = re.match(r"#\s+(.+)", line.strip())
        if m:
            return m.group(1).strip()
    return fallback


def render_body(md_text):
    return markdown.markdown(md_text, extensions=EXTENSIONS)


def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python render.py <slug>")

    slug = sys.argv[1]
    if slug.endswith(".md"):
        slug = slug[:-3]

    src = Path(f"{slug}.md")
    if not src.exists():
        sys.exit(f"Not found: {src}  (run from the drafts/ directory)")

    md_text = src.read_text(encoding="utf-8")
    title = extract_title(md_text, slug)
    body = render_body(md_text)

    # ── Clean build — no review tooling, ever. This is the Substack paste source.
    clean = PAGE.format(title=title, css=CSS, banner="", body=body, review="")
    clean_path = Path(f"{slug}.html")
    clean_path.write_text(clean, encoding="utf-8")

    # Enforce the hard invariant: review tooling must never reach the clean build.
    if REVIEW_MARKER in clean_path.read_text(encoding="utf-8"):
        sys.exit(f"INVARIANT VIOLATION: review tooling ('{REVIEW_MARKER}') leaked into {clean_path}")

    outputs = [str(clean_path)]

    # ── Review build — banner + comment layer. Never publish this one.
    if os.environ.get("BLOG_REVIEW") == "1":
        banner = ""
        notes = Path("revision-notes.md")
        if notes.exists():
            banner = (
                '<div class="revision-banner">'
                + render_body(notes.read_text(encoding="utf-8"))
                + "</div>\n"
            )

        review_layer = ""
        snippet = Path("review-snippet.html")
        if snippet.exists():
            review_layer = snippet.read_text(encoding="utf-8") + "\n"
        else:
            print("Note: review-snippet.html not found — review build has no comment layer.")

        review_page = PAGE.format(
            title=f"{title} — review", css=CSS, banner=banner, body=body, review=review_layer
        )
        review_path = Path(f"{slug}-review.html")
        review_path.write_text(review_page, encoding="utf-8")
        outputs.append(str(review_path))

    print("Wrote: " + ", ".join(outputs))


if __name__ == "__main__":
    main()
