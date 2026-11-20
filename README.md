# Skills

A suite of Claude Code skills for running a software engineering loop with AI. Each skill handles one step of the loop, from a rough idea through to shipped code, and hands what it produces to the next.

- [`/refine`](skills/refine/SKILL.md): interviews you about a piece of work until its goal, acceptance criteria and boundaries are sharp enough to become a ticket. A read-only scout agent answers its questions about the code, and it needs a human to answer its questions about the work.
- [`/to-ticket`](skills/to-ticket/SKILL.md): publishes a spec from `/refine` to GitHub as an issue. It creates a new issue, or replaces the one the spec was refined from, and deletes the local copy once the issue is up.
