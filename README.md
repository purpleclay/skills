# Skills

A suite of Claude Code skills for running a software engineering loop with AI. Each skill handles one step of the loop, from a rough idea through to shipped code, and hands what it produces to the next.

- [`/refine`](skills/refine/SKILL.md): interviews you about a piece of work until its goal, acceptance criteria and boundaries are sharp enough to become a ticket. A read-only scout agent answers its questions about the code, checking the web or any MCP server you have connected when the work depends on something outside the repository, such as a library or a standard. The spec lists the public sources it rests on. `/refine` needs a human to answer its questions about the work. It saves the spec after every round, so an interview that stops can be picked up again: run `/refine` on its own to see your saved specs. Where Claude Code can show a panel beside the chat, the spec appears there as the interview shapes it, and the panel closes once `/to-tickets` has published it.
- [`/to-tickets`](skills/to-tickets/SKILL.md): publishes a spec from `/refine` to GitHub. A spec an agent can build within one context window becomes one issue. A larger one becomes several, which you approve as a table first, and GitHub's issue dependencies link them in the order they must merge. The first ticket replaces the issue the spec was refined from, if there is one, and the local copy goes once every ticket is up.

> [!NOTE]
> `/to-tickets` publishes with the [GitHub CLI](https://cli.github.com), so it needs `gh` installed and signed in.

## Install

From within Claude Code:

```sh
/plugin install purpleclay-skills --marketplace purpleclay/skills
```
