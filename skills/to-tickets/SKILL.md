---
name: to-tickets
description: Publish a spec saved by /refine to GitHub. A surveyor checks the spec against the code and sizes it, and the engineer approves the tickets before any is published, one ticket when the work fits in one agent's context and as few linked tickets as fit when it does not.
argument-hint: "[spec path]"
disable-model-invocation: true
---

# To tickets

Publish one spec from `/refine` to GitHub. Work that one agent can deliver within its context becomes one issue. Larger work becomes as few issues as will each fit, each blocked by the tickets it needs. Never change a word of the spec.

Input: $ARGUMENTS

## Pick the spec

A spec whose front matter has `state: in progress` is still being refined. Never list, mention or publish one. Only if the input gives its path, say that `/refine` is still refining it and stop without running `gh`.

1. If the input gives a path, publish that file.
2. Otherwise, if `/refine` saved a spec ready to publish earlier in this session, publish that one.
3. Otherwise list the `.md` files directly inside `<git-dir>/refine/`, where `git rev-parse --path-format=absolute --git-common-dir` gives `<git-dir>`, and ask the engineer which one to publish. If there are none, say there is nothing to publish and stop without running `gh`.

Read the spec before you run anything else. Only once it is not in progress, run `gh auth status`. If it fails, ask the engineer to run `gh auth login` and then this command again, and stop.

The spec's tickets directory is its path with `.md` replaced by `.tickets`. If that directory exists, the engineer has already approved a breakdown of this spec: go straight to **Publish a breakdown**, and do not survey, propose or ask about one again.

## Where tickets go

Every ticket is a new issue in the current repository. Never edit an existing issue, even when the input names one or the spec's front matter records one, and never search for one to match.

## Survey the code

Send the spec to the `purpleclay-skills:surveyor` agent: its whole text from the title down, and nothing else. Wait for its report before you decide anything. Never read, search or list repository files yourself: the survey is your only view of the code. None of it goes into a ticket: no paths, function names or estimates.

If it lists under "Does not match the spec" something the spec says about the code today that the code proves false, the code has changed since the spec was written. List each such mismatch, as behaviour, and ask the engineer whether to go on with the spec as it stands. A gap or open question the survey raises is not a mismatch: never ask about one. Publish and write nothing until they answer.

- If they go on, carry on below with the spec unchanged.
- If they judge the spec no longer valid, create no tickets. Tell them to refine it again with `/refine` in a separate session, and stop.

If the surveyor cannot run or does not report, say so and stop. Publish nothing.

## Label

Every ticket of the spec carries one label: `bug` when the spec's goal is to fix behaviour that is wrong today, and `enhancement` otherwise. Never give any other label.

Check GitHub before you show the tickets, so that the engineer approves the labels the issues will really carry:

```sh
gh label list --limit 1000 --json name --jq '.[].name'
```

If the label is not among them, or the command fails, the tickets carry no label. Never create one. Never name a label the repository does not have, in the table, around it or in your report: not even to say it is missing. The engineer sees only the label each issue will carry.

## One ticket or several

A ticket fits when one agent can deliver it within a context window of about 200k tokens: read the code it touches, make the change, and write and run its tests until they pass. Judge it from the survey's estimate of the tokens that takes. Never judge it from lines of code or the number of criteria.

Size is the only reason to split. A spec that fits is one ticket, however many acceptance criteria it has: never split it to make a pull request smaller.

Otherwise break it into the fewest tickets that each fit:

- Each acceptance criterion of the spec goes, word for word, into exactly one ticket. No ticket has a criterion that the spec does not.
- Every ticket delivers at least one criterion. Work that only prepares the ground for other tickets goes into the first ticket that needs it.
- Keep criteria that the survey maps to the same area in one ticket, unless that area alone does not fit.
- Each ticket can merge without breaking main once the tickets that block it have merged. A ticket is blocked only by tickets it cannot merge without.
- Number the tickets so that every ticket comes after the tickets that block it.

## Propose the tickets

Write every proposal into your reply, where the engineer can read it, before you publish or write anything, even when it is a single ticket. Open with one line giving the survey's estimate in tokens against the 200k limit. Then show a table with one row per ticket and the columns `#`, `Title`, `Label` (the label it will carry, or "None") and `Blocked by` (the numbers of the tickets that block it, or "Nothing"), and ask the engineer to approve it. Publish and write nothing until they do. If the input already says how they will answer, still write the table into your reply first, then act on that answer as if they had just given it.

- If they approve one ticket, go to **Publish one ticket**.
- If they approve several, save the breakdown, then go to **Publish a breakdown**.
- If they reject it, ask what is wrong, unless they already said. Then propose new tickets that fix it, show the table and ask again.
- If they say stop, stop. Publish nothing, write nothing, and leave the spec as it is.

## Save the breakdown

Write each ticket to `<n>.md`, where `<n>` is its number, in a draft directory: the tickets directory's path with `.draft` added, emptied first if an earlier run left one. Once every ticket is written, rename the draft directory to the tickets directory with `mv`, so that the tickets directory only ever holds a whole breakdown. A ticket has the spec's format and stands alone, so that an agent can build it without reading the spec or any other ticket:

```markdown
---
blocked-by: <the numbers of the tickets that block it, separated by spaces, or nothing>
label: <its label, or nothing>
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

1. The issue's title is the text of the file's first `# ` heading, and its body is everything after that heading line, unchanged. Front matter sits above the heading, so it is never published. Read both straight from the file, so that nothing passes through your own retyping. Leave out `--label` when the ticket carries no label:
   ```sh
   awk 'f; /^# / && !f {f=1}' "<file>" | gh issue create --title "$(grep -m1 '^# ' "<file>" | cut -c3-)" --body-file - --label "<label>"
   ```
2. If that command fails, show the engineer its error and stop. Do not retry, and keep the spec. A failure can come after GitHub has already made the issue, and a retry would then make a duplicate.
3. If it succeeds, delete the spec file, report the issue's URL, and stop.

## Publish a breakdown

Take the tickets in number order:

1. If the ticket's front matter has `publishing: yes` but no `published:` URL, an earlier run may have created its issue and then failed. Ask the engineer for that issue's URL, or to confirm that GitHub never made it, and publish nothing until they answer. Record a URL they give as `published:`, and remove `publishing: yes` either way.
2. If the ticket's front matter has no `published:` URL, publish its file as in **Publish one ticket**, step 1, with the label its front matter records. Before you do, add `publishing: yes` to its front matter. Once the command succeeds, replace `publishing: yes` with `published: <the issue's URL>` straight away.
3. For each number in its `blocked-by`, mark the published issue as blocked by that ticket's issue, then remove the number from `blocked-by`. Take each issue's owner, repository and number from its own `published:` URL, since a breakdown published before every ticket became a new issue may span two repositories:
   ```sh
   gh api repos/<owner>/<repo>/issues/<number>/dependencies/blocked_by -F issue_id="$(gh api repos/<blocker owner>/<blocker repo>/issues/<blocker number> --jq .id)"
   ```

If any command fails, show the engineer its error and stop. Do not retry, and keep the spec and its tickets directory: running this command again carries on from where it stopped. If it was a publish that failed, tell the engineer to check whether GitHub made it anyway, since the next run will ask.

Once every ticket is published and has nothing left in `blocked-by`, delete the spec and its tickets directory, report every issue's URL, and stop.
