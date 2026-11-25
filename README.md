# Skills

Claude Code skills for an AI-assisted engineering loop, from a rough idea to shipped code. Each skill does one step and hands its output to the next.

- [`/refine`](skills/refine/SKILL.md): interviews you about an idea until it is sharp enough to become a ticket. A read-only scout looks up the facts, so you only answer questions about the work. Interviews can be stopped and picked up again.
- [`/to-ticket`](skills/to-ticket/SKILL.md): publishes a spec from `/refine` as one GitHub issue, labelled `bug` or `enhancement`.

> [!NOTE]
> `/to-ticket` needs the [GitHub CLI](https://cli.github.com) installed and signed in.

## Install

From within Claude Code:

```sh
/plugin install purpleclay-skills --marketplace purpleclay/skills
```
