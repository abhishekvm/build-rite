"""Merge, verify-adjust, rank and render audit findings (stdlib only).

  python3 postprocess.py merge <workflow-output-file> <workdir> [overrides.json]
      -> <workdir>/findings.json, <workdir>/groups.txt (review every multi-item group!)
      overrides.json: {"<raw index>": "<group name>"} forces items into a named group;
      use a fresh name to split an item out of a wrong group.
  python3 postprocess.py build <workdir> <narrative.html> <out.html> <title> <subtitle>
      -> self-contained local HTML report
"""

import collections
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).parent
R = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
EFFORT_DAYS = {"S": 0.5, "M": 3, "L": 10}
STOP = set("that this with from when every into than then they there their about after before which while where have does doesn't only also over under user users code".split())


def load_results(path):
    o = json.load(open(path))
    data = o.get("result", o) if isinstance(o, dict) else o
    return json.loads(data) if isinstance(data, str) else data


def final_severity(f):
    """Least severe rating among non-refuting verifiers (conservative); refuted by all -> dropped.
    A merged group then takes the most severe of its members (see merge)."""
    votes = f.get("verification")
    if votes is None:
        return f["severity"], "not verified (P2/P3)"
    standing = [v for v in votes if v["verdict"] != "refuted"]
    if not standing:
        return None, "refuted"
    sev = max((v["severity"] if v["severity"] != "none" else f["severity"] for v in standing), key=R.get)
    return sev, "confirmed" if sev == f["severity"] else f"downgraded from {f['severity']}"


def tokens(s):
    return {w for w in re.findall(r"[a-z0-9_/.-]{4,}", s.lower()) if w not in STOP}


def primary_file(loc):
    m = re.match(r"\s*([\w./-]+\.\w+)", loc or "")
    return m.group(1) if m else ""


def merge(out_file, workdir, overrides_path=None):
    wd = pathlib.Path(workdir)
    results = load_results(out_file)
    items = []
    for d in results:
        for f in d["findings"]:
            sev, status = final_severity(f)
            if sev:
                items.append(dict(f, source=d["source"], final=sev, status=status))
    # union-find on title similarity (stricter across files)
    parent = list(range(len(items)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    toks = [tokens(it["title"]) for it in items]
    files = [{m for m in re.findall(r"[\w/-]+\.\w{1,5}", it["location"] or "")} for it in items]
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i]["source"] == items[j]["source"]:
                continue
            a, b = toks[i], toks[j]
            jac = len(a & b) / max(1, len(a | b))
            if jac >= 0.4 or (files[i] & files[j] and jac >= 0.2):
                parent[find(i)] = find(j)
    groups = collections.defaultdict(list)
    overrides = json.load(open(overrides_path)) if overrides_path else {}
    for i, it in enumerate(items):
        it["raw"] = i
        groups[overrides.get(str(i), f"auto{find(i)}")].append(it)

    out = []
    for g in groups.values():
        g.sort(key=lambda x: (R[x["final"]], x["status"] != "confirmed", {"high": 0, "medium": 1, "low": 2}[x["confidence"]]))
        rep = dict(g[0])
        v = rep["value"]
        cost = EFFORT_DAYS[rep["effort"]] * float(rep.get("change_risk") or 1)
        rep.update(
            sources=sorted({x["source"] for x in g}), dupes=len(g), also=[x["title"] for x in g[1:]],
            raw_ids=[x["raw"] for x in g], value_sum=sum(v.values()), cost=round(cost, 2),
            roi=round(sum(v.values()) / cost, 1),
            verdicts=[dict(verdict=vv["verdict"], severity=vv["severity"], reasoning=vv["reasoning"][:700])
                      for x in g for vv in (x.get("verification") or [])][:3],
        )
        rep.pop("verification", None)
        out.append(rep)
    out.sort(key=lambda r: (r["final"] != "P0", -r["roi"], R[r["final"]]))
    for n, r in enumerate(out, 1):
        r["id"] = f"F{n:03d}"
    (wd / "findings.json").write_text(json.dumps(out))

    lines = [f"{len(items)} raw -> {len(out)} unique  {dict(collections.Counter(r['final'] for r in out))}", ""]
    for r in out:
        if r["dupes"] > 1:
            lines.append(f"{r['id']} {r['final']} [{','.join(map(str, r['raw_ids']))}] {r['title'][:110]}")
            lines += [f"      + {a[:110]}" for a in r["also"]]
    lines += ["", "P0/P1:"] + [f"{r['id']} {r['final']} {r['status']} {r['category']} {r['effort']} ROI {r['roi']} | {r['title'][:110]}"
                               for r in out if r["final"] in ("P0", "P1")]
    lines += ["", "Themes reported by finders:"] + sorted({t for d in results for t in (d.get("themes") or [])})
    lines += ["", "Coverage skipped:"] + [f"{d['source']}: {d['coverage'].get('skipped', '')}" for d in results]
    lines += ["", "Deletion candidates:"] + [f"{d['source']}: {c['unit']} ({c['loc']} lines) — {c['static_proof'][:120]}"
                                             for d in results for c in (d.get("deletion_candidates") or [])]
    (wd / "groups.txt").write_text("\n".join(lines))
    print("\n".join(lines[:80]))


def build(workdir, narrative, out_html, title, subtitle):
    tpl = (HERE / "report-template.html").read_text()
    data = (pathlib.Path(workdir) / "findings.json").read_text().replace("</", "<\\/")
    html = (tpl.replace("__TITLE__", title).replace("__SUBTITLE__", subtitle)
               .replace("<!--NARRATIVE-->", pathlib.Path(narrative).read_text())
               .replace("__FINDINGS_JSON__", data))
    pathlib.Path(out_html).write_text(html)
    print("wrote", out_html, len(html) // 1024, "KB")


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "merge":
        merge(*sys.argv[2:5])
    elif cmd == "build":
        build(*sys.argv[2:7])
    else:
        sys.exit(__doc__)
