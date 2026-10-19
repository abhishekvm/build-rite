"""Step-0 code-health metrics -> SUMMARY.md (stdlib only).

Inputs in <workdir>/metrics/: lizard.csv (uvx lizard --csv), churn.txt
(git log --name-only --format=COMMIT:%s). Optional: deadcode.txt, deps.txt
(language-specific tool output, copied verbatim into the summary).

usage: python3 metrics.py <workdir> <src_root_prefix> [module_depth=2]
"""

import collections
import csv
import pathlib
import re
import sys

wd = pathlib.Path(sys.argv[1]) / "metrics"
root = sys.argv[2].rstrip("/") + "/"
depth = int(sys.argv[3]) if len(sys.argv) > 3 else 2


def module(path):
    rel = path.split(root, 1)[-1]
    parts = rel.split("/")
    return "/".join(parts[: min(depth, len(parts) - 1)]) or parts[0]


# lizard --csv columns: NLOC, CCN, token, PARAM, length, location, file, function, long_name, start, end
funcs = []
for row in csv.reader(open(wd / "lizard.csv", encoding="utf-8", errors="replace")):
    if len(row) < 11 or not row[0].isdigit():
        continue
    funcs.append(dict(nloc=int(row[0]), ccn=int(row[1]), length=int(row[4]), file=row[6], name=row[7], start=int(row[9])))

churn, fixes, msg = collections.Counter(), collections.Counter(), ""
for line in open(wd / "churn.txt", encoding="utf-8", errors="replace"):
    line = line.strip()
    if line.startswith("COMMIT:"):
        msg = line[7:].lower()
    elif line:
        churn[line] += 1
        if re.search(r"\bfix|bug|hotfix", msg):
            fixes[line] += 1

M = collections.defaultdict(lambda: dict(nloc=0, files=set(), fn=0, hi=0, mx=0, commits=0))
file_nloc, file_cc = collections.Counter(), collections.Counter()
for f in funcs:
    m = M[module(f["file"])]
    m["nloc"] += f["nloc"]; m["files"].add(f["file"]); m["fn"] += 1
    m["hi"] += f["ccn"] > 15; m["mx"] = max(m["mx"], f["ccn"])
    file_nloc[f["file"]] += f["nloc"]; file_cc[f["file"]] += f["ccn"]
for path, n in churn.items():
    for f in file_nloc:
        if f.endswith(path) or path.endswith(f.lstrip("./")):
            M[module(f)]["commits"] += n
            break


def commits_for(f):
    return next((n for p, n in churn.items() if f.endswith(p) or p.endswith(f.lstrip("./"))), 0)


def fixes_for(f):
    return next((n for p, n in fixes.items() if f.endswith(p) or p.endswith(f.lstrip("./"))), 0)


out = ["# Step-0 metrics", "",
       f"Totals: {sum(file_nloc.values()):,} NLOC in functions, {len(funcs):,} functions, "
       f"{sum(f['ccn'] > 15 for f in funcs)} with CCN>15.", "",
       "## Modules (NLOC | files | functions | CCN>15 | max CCN | 12-mo commits)"]
for k, v in sorted(M.items(), key=lambda kv: -kv[1]["nloc"])[:25]:
    out.append(f"{k}: {v['nloc']:,} | {len(v['files'])} | {v['fn']} | {v['hi']} | {v['mx']} | {v['commits']}")
out += ["", "## Worst functions (CCN, length)"]
for f in sorted(funcs, key=lambda f: -f["ccn"])[:20]:
    out.append(f"{f['ccn']} {f['file']}:{f['start']} {f['name']} ({f['length']} lines)")
out += ["", "## Biggest files (NLOC in functions)"]
for f, n in file_nloc.most_common(15):
    out.append(f"{n:,} {f}")
out += ["", "## Hotspots (commits × ΣCCN | commits | fix commits | ΣCCN | file)"]
hot = sorted(((commits_for(f) * c, commits_for(f), fixes_for(f), c, f) for f, c in file_cc.items()), reverse=True)[:20]
out += [" | ".join(map(str, h)) for h in hot if h[0]]
for name in ("deadcode.txt", "deps.txt"):
    p = wd / name
    if p.exists():
        out += ["", f"## {name} (raw tool output — verify every item by hand)", "```", p.read_text(errors="replace")[-4000:], "```"]
(wd / "SUMMARY.md").write_text("\n".join(out) + "\n")
print("\n".join(out[:60]))
