# Skills

Claude Code skills for an AI-assisted engineering loop, from a rough idea to shipped code. Each skill does one step and hands its output to the next.

- [`/refine`](skills/refine/SKILL.md): interviews you about an idea until it is sharp enough to become a ticket. A read-only scout looks up the facts, so you only answer questions about the work. Interviews can be stopped and picked up again.
- [`/to-tickets`](skills/to-tickets/SKILL.md): publishes a spec from `/refine` as GitHub issues labelled `bug` or `enhancement`. A read-only surveyor checks the spec against the code and sizes it, so it is one issue when one agent can deliver it within its context window, and as few linked issues as fit when it cannot. You approve the issues before any is published.

> [!NOTE]
> `/to-tickets` needs the [GitHub CLI](https://cli.github.com) installed and signed in.

## Install

From within Claude Code:

```sh
/plugin install purpleclay-skills --marketplace purpleclay/skills
```
