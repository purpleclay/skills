---
name: to-tickets
description: Publish a spec saved by /refine to GitHub, as one issue, or as several issues linked in the order they must merge when the work is too large for one.
argument-hint: "[spec path]"
disable-model-invocation: true
---

# To tickets

Publish one spec from `/refine` to GitHub. A spec that an agent can build within one context window becomes one issue. A larger spec becomes several, each blocked by the tickets it needs. The engineer ran this command on purpose: publish a single ticket without asking, and never change a word of the spec.

Input: $ARGUMENTS

## Pick the spec

A spec whose front matter has `state: in progress` is still being refined. Never list, mention or publish one. Only if the input gives its path, say that `/refine` is still refining it and stop without running `gh`.

1. If the input gives a path, publish that file.
2. Otherwise, if `/refine` saved a spec ready to publish earlier in this session, publish that one.
3. Otherwise list the `.md` files directly inside `<git-dir>/refine/`, where `git rev-parse --path-format=absolute --git-common-dir` gives `<git-dir>`, and ask the engineer which one to publish. If there are none, say there is nothing to publish and stop without running `gh`.

The spec's tickets directory is its path with `.md` replaced by `.tickets`. If that directory exists, the engineer has already approved a breakdown of this spec: go straight to **Publish a breakdown**, and do not propose or ask about one again.

## Where tickets go

Every ticket is a new issue in the current repository. Never edit an existing issue, even when the input names one or the spec's front matter records one, and never search for one to match.

## One ticket or several

A ticket fits when an agent starting from an empty context could read the code it touches, make the change and write its tests, with room to spare. Judge this from the spec. If you are unsure, it fits: one ticket means one pull request to review and less noise.

If the spec fits, go to **Publish one ticket**. Show no breakdown and ask nothing.

Otherwise break it into tickets:

- Each acceptance criterion of the spec goes, word for word, into exactly one ticket. No ticket has a criterion that the spec does not.
- Each ticket fits, and can merge without breaking main once the tickets that block it have merged. A ticket is blocked only by tickets it cannot merge without.
- Number the tickets so that every ticket comes after the tickets that block it.

Show the breakdown as a table with one row per ticket and the columns `#`, `Title`, `Delivers` (one line) and `Blocks` (the numbers of the tickets it blocks). Write every breakdown you propose into your reply, where the engineer can read it, before you publish or write anything, and ask them to approve it. Publish and write nothing until they do. If the input already says how they will answer a breakdown, still write its table into your reply first, then act on that answer as if they had just given it.

- If they approve, save the breakdown, then go to **Publish a breakdown**.
- If they reject it, ask what is wrong, unless they already said. Then propose a new breakdown that fixes it, show its table and ask again.
- If they say stop, stop. Publish nothing, write nothing, and leave the spec as it is.

## Save the breakdown

Write each ticket to `<n>.md`, where `<n>` is its number, in a draft directory: the tickets directory's path with `.draft` added, emptied first if an earlier run left one. Once every ticket is written, rename the draft directory to the tickets directory with `mv`, so that the tickets directory only ever holds a whole breakdown. A ticket has the spec's format and stands alone, so that an agent can build it without reading the spec or any other ticket:

```markdown
---
blocked-by: <the numbers of the tickets that block it, separated by spaces, or nothing>
---

# <An outcome in the imperative>

## Goal

<What this ticket changes, for whom, and why.>

## Current behaviour

<What happens today in the part this ticket changes.>

## Acceptance criteria

- [ ] <The spec's criteria that this ticket delivers, word for word>

## Out of scope

- <The spec's entries that apply, and the work that other tickets deliver, described as behaviour>

## Constraints

- <The spec's constraints that apply>
- Public contract change: yes / no
- Data migration: yes / no
- Security boundary: yes / no

## Sources

- <The spec's sources that this ticket's facts rest on. Leave out this heading when there are none.>
```

No ticket mentions another ticket, the spec or the breakdown. GitHub links them through issue dependencies.

## Publish one ticket

1. Run `gh auth status`. If it fails, ask the engineer to run `gh auth login` and then this command again, and stop. Post nothing.
2. The issue's title is the text of the file's first `# ` heading, and its body is everything after that heading line, unchanged. Front matter sits above the heading, so it is never published. Read both straight from the file, so that nothing passes through your own retyping:
   ```sh
   awk 'f; /^# / && !f {f=1}' "<file>" | gh issue create --title "$(grep -m1 '^# ' "<file>" | cut -c3-)" --body-file -
   ```
3. If that command fails, show the engineer its error and stop. Do not retry, and keep the spec. A failure can come after GitHub has already made the issue, and a retry would then make a duplicate.
4. If it succeeds, delete the spec file, report the issue's URL, and stop.

## Publish a breakdown

Run `gh auth status` as in **Publish one ticket**. Then take the tickets in number order:

1. If the ticket's front matter has `publishing: yes` but no `published:` URL, an earlier run may have created its issue and then failed. Ask the engineer for that issue's URL, or to confirm that GitHub never made it, and publish nothing until they answer. Record a URL they give as `published:`, and remove `publishing: yes` either way.
2. If the ticket's front matter has no `published:` URL, publish its file as in **Publish one ticket**, step 2. Before you do, add `publishing: yes` to its front matter. Once the command succeeds, replace `publishing: yes` with `published: <the issue's URL>` straight away.
3. For each number in its `blocked-by`, mark the published issue as blocked by that ticket's issue, then remove the number from `blocked-by`. Take each issue's owner, repository and number from its own `published:` URL, since a breakdown published before every ticket became a new issue may span two repositories:
   ```sh
   gh api repos/<owner>/<repo>/issues/<number>/dependencies/blocked_by -F issue_id="$(gh api repos/<blocker owner>/<blocker repo>/issues/<blocker number> --jq .id)"
   ```

If any command fails, show the engineer its error and stop. Do not retry, and keep the spec and its tickets directory: running this command again carries on from where it stopped. If it was a publish that failed, tell the engineer to check whether GitHub made it anyway, since the next run will ask.

Once every ticket is published and has nothing left in `blocked-by`, delete the spec and its tickets directory, report every issue's URL, and stop.
