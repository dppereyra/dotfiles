---
name: use-ai-team
description: Route a request to the AI agent fleet through mgr-product-owner instead of handling it directly. Use when the user asks to use "the agents", "the team", or "the AI team" for a task, or explicitly invokes /use-ai-team.
metadata:
  argument-hint: "the request or epic to hand to the team"
---

# Use AI Team

This skill hands a request to the agent fleet rather than doing the work yourself. The single
entry point is the `mgr-product-owner` agent — it is the only one you launch directly.

## What to do

1. Take the request in `$ARGUMENTS` (or, if empty, the request the user just made in
   conversation) and launch the `Agent` tool with `subagent_type: mgr-product-owner`.
2. Write a self-contained prompt for it: state the request in full, plus any context already
   established in this conversation that mgr-product-owner would otherwise have to re-derive
   (project directory, prior decisions, constraints the user already stated). It has no memory
   of this conversation.
3. Do not break the request down yourself, and do not call `dev-*`, `ops-*`, `db-*`, `qa-*`, or
   `rnd-library` directly — that sequencing is mgr-product-owner's job. It gathers input from
   the relevant leads, drafts Trello cards, and drives them to Done.
4. Default to running it in the **background** unless the user's phrasing implies they want to
   wait synchronously for a quick answer (e.g. "ask the team what they think" vs. "have the team
   build this"). If genuinely unsure, ask.
5. When it reports back (or, for a foreground call, when it returns), relay its summary to the
   user: cards created/moved, what each lead said, anything it escalated for the user to decide.
   Do not silently absorb or re-narrate its findings as your own.

## What not to do

- Don't re-plan the work in parallel "just in case" — that duplicates what mgr-product-owner is
  already doing and wastes the run.
- Don't skip mgr-product-owner and go straight to a domain lead because the request looks like
  it obviously belongs to one team — mgr-product-owner still owns scoping it into cards and
  tracking them to Done.
- Don't fabricate a Trello board name or workflow on its behalf — that's a question
  mgr-product-owner asks the user directly when needed.
