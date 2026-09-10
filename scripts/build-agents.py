#!/usr/bin/env python3
"""Render the agent fleet from src/agents/ into every tool's native format.

Single source of truth: src/agents/<name>.md, plus the shared blocks in
src/agents/_standards/. Each agent declares a `role` and the shared operating
standards, Trello card write-back protocol, and reporting format are inlined at
build time, so a rule is edited in exactly one place.

An agent may override a shared block by defining that section inline in its own
source file -- used by the advisory agents (mgr-*, ops-architect, ops-automation),
whose standards are genuinely role-specific rather than duplicated.

Usage: python3 scripts/build-agents.py [--check]
       --check verifies the committed output is up to date (exit 1 if stale).
"""

from __future__ import annotations

import re
import sys
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src/agents"
STD = SRC / "_standards"
CFG = ROOT / "src/configs"

TARGETS = {
    "claude": CFG / ".claude/agents",
    "opencode": CFG / ".config/opencode/agents",
    "copilot": CFG / ".copilot/agents",
    "gemini": CFG / ".gemini/config/agents",
    "codex": CFG / ".codex/agents",
}

COPILOT_TOOLS = '["agent", "read", "search", "edit", "execute"]'


def parse_source(path: pathlib.Path) -> tuple[dict, str]:
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", path.read_text(), re.S)
    if not m:
        raise SystemExit(f"{path}: missing frontmatter")
    meta = {}
    for line in m.group(1).split("\n"):
        k, _, v = line.partition(":")
        v = v.strip()
        if len(v) > 1 and v[0] == '"' and v[-1] == '"':
            v = v[1:-1]  # stored quoted so the description can hold colons
        meta[k.strip()] = v
    return meta, m.group(2).strip("\n")


def has_section(body: str, title: str) -> bool:
    return any(l.startswith("## ") and l[3:].strip() == title for l in body.split("\n"))


def resolve(meta: dict, body: str) -> str:
    """Inline the shared blocks for this agent's role."""
    role = meta["role"]

    def shared(stem: str) -> str:
        path = STD / f"{stem}.md"
        if not path.exists():
            raise SystemExit(f"{meta['name']}: role '{role}' needs missing {path.name}")
        return path.read_text().strip()

    # Advisory agents define their own standards inline, so nothing is loaded for them.
    out = body
    if "{{STANDARDS}}" in out:
        out = out.replace("{{STANDARDS}}", shared(f"{role}.standards"))

    # {{CLOSING}} is the card protocol; reporting follows unless overridden inline.
    tail = shared("card-write-back")
    if not has_section(out, "Reporting"):
        tail += "\n\n" + shared(f"{role}.reporting")
    out = out.replace("{{CLOSING}}", tail)

    if "{{" in out:
        raise SystemExit(f"{meta['name']}: unresolved marker in body")
    return re.sub(r"\n{3,}", "\n\n", out).strip() + "\n"


def short_desc(desc: str) -> str:
    """The examples block is Claude-only; every other tool takes the lead line."""
    return desc.split("\\n\\nExamples:")[0]


def render(tool: str, meta: dict, body: str) -> str:
    name, color = meta["name"], meta["color"]
    primary = meta.get("primary", "false") == "true"
    desc, sdesc = meta["description"], short_desc(meta["description"])

    if tool == "claude":
        return (f'---\nname: {name}\ndescription: "{desc}"\n'
                f"model: sonnet\ncolor: {color}\n---\n\n{body}")

    if tool == "opencode":
        return (f'---\ndescription: "{sdesc}"\n'
                f'mode: {"primary" if primary else "subagent"}\n'
                f"color: {color}\n---\n{body}")

    if tool == "copilot":
        delegates = [d.strip() for d in meta.get("delegates", "").split(",") if d.strip()]
        agents = "[" + ", ".join(f'"{d}"' for d in delegates) + "]"
        return (f'---\nname: {name}\ndescription: "{sdesc}"\n'
                f"tools: {COPILOT_TOOLS}\nagents: {agents}\n"
                f"user-invocable: true\ndisable-model-invocation: false\n---\n{body}")

    if tool == "gemini":
        return (f'---\nname: {name}\ndescription: "{sdesc}"\nsubagent: true\n'
                f'mainAgent: {"true" if primary else "false"}\n'
                f"model: inherit\ncommandExecutionPolicy: sandbox\n---\n\n"
                f"# System Prompt\n{body}")

    if tool == "codex":
        if '"""' in body:
            raise SystemExit(f"{name}: body contains a TOML triple-quote delimiter")
        return (f'name = "{name}"\ndescription = "{sdesc}"\n'
                f'sandbox_mode = "workspace-write"\n'
                f'developer_instructions = """\n{body}"""\n')

    raise SystemExit(f"unknown tool {tool}")


def filename(tool: str, name: str) -> str:
    if tool == "copilot":
        return f"{name}.agent.md"
    if tool == "codex":
        return f"{name}.toml"
    return f"{name}.md"


def main() -> int:
    check = "--check" in sys.argv
    sources = sorted(SRC.glob("*.md"))
    if not sources:
        raise SystemExit(f"no agent sources in {SRC}")

    wanted: dict[pathlib.Path, str] = {}
    for path in sources:
        meta, raw = parse_source(path)
        body = resolve(meta, raw)
        for tool, outdir in TARGETS.items():
            wanted[outdir / filename(tool, meta["name"])] = render(tool, meta, body)

    stale, written = [], 0
    for path, content in wanted.items():
        current = path.read_text() if path.exists() else None
        if current == content:
            continue
        stale.append(path)
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
            written += 1

    # Remove renders for agents that no longer have a source file.
    orphans = []
    for tool, outdir in TARGETS.items():
        if not outdir.is_dir():
            continue
        for existing in outdir.iterdir():
            if existing.is_file() and existing not in wanted:
                orphans.append(existing)
                if not check:
                    existing.unlink()

    if check:
        if stale or orphans:
            for p in stale:
                print(f"stale:  {p.relative_to(ROOT)}")
            for p in orphans:
                print(f"orphan: {p.relative_to(ROOT)}")
            print(f"\n{len(stale)} stale, {len(orphans)} orphaned -- run scripts/build-agents.py")
            return 1
        print(f"up to date: {len(sources)} agents x {len(TARGETS)} tools = {len(wanted)} files")
        return 0

    print(f"{len(sources)} agents x {len(TARGETS)} tools -> {len(wanted)} files "
          f"({written} written, {len(orphans)} removed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
