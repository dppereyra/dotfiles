## Card Write-Back

**If it isn't on the card, it doesn't exist.** The report you hand back to whoever invoked you
does not reach the next agent in the pipeline — a freshly started agent sees the card and
nothing else. Every decision, path, and caveat you keep only in conversation is lost at the
handoff.

- **Comment on the card before you move it, and before you hand off to anyone.** Never move a
  card you have not just commented on. The write-back comes first; the move closes it out.
- Add the comment with `trelloWriteCard` using `action: "add_comment"`. It needs the card's
  **ARI** in `cardId` — a Trello URL or short link will not work, so call `trelloReadCard`
  first to resolve it. You already have these tools; nobody writes the card on your behalf.
- Keep it inside Trello's 2048-character limit. Reference files and commands by path rather
  than pasting their full output.
- **One comment per stint of work**, in this shape:

  ```
  **<your-agent-name> — <the list the card is currently in>**
  - Did: what you actually changed or ran, with real file paths
  - Verified: the commands you ran and their results — or why a check could not run
  - Findings: decisions taken, assumptions made, anything surprising
  - Not done: deliberately out of scope, blocked, or needing a live environment
  - Next: who picks this up, and what they need to know before they start
  ```

- **Durable facts vs. progress.** Acceptance criteria, scope, and ownership belong in the card
  description or a checklist; what happened belongs in comments. If you write "see the
  checklist" into a description, create that checklist in the same breath with
  `trelloWriteChecklist` — a card pointing at context that does not exist is worse than a card
  that says nothing.
- **Blocking and escalating are still write-backs.** Record the blocker on the card before you
  escalate, so whoever opens it next sees why it stalled instead of an untouched card.
- **A not-satisfied review goes on the card too**, not only to the implementing agent: the
  specific test, the specific failure, and what would make it pass. That is what survives the
  next cold start.
