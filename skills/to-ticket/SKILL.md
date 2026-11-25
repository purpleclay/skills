---
name: to-ticket
description: Publish a spec saved by /refine to GitHub as one issue, labelled bug or enhancement.
argument-hint: "[spec path]"
disable-model-invocation: true
---

# To ticket

Publish one spec from `/refine` to GitHub as one new issue in the current repository. The engineer ran this command on purpose: publish without asking, and never change a word of the spec.

Input: $ARGUMENTS

## Pick the spec

Read the spec on its own, before you run `gh` or anything else. A spec whose front matter has `state: in progress` is still being refined. Never list, mention or publish one. Only if the input gives its path, say that `/refine` is still refining it and stop without running `gh`.

1. If the input gives a path, publish that file.
2. Otherwise, if `/refine` saved a spec ready to publish earlier in this session, publish that one.
3. Otherwise list the `.md` files directly inside `<git-dir>/refine/`, where `git rev-parse --path-format=absolute --git-common-dir` gives `<git-dir>`, and ask the engineer which one to publish. If there are none, say there is nothing to publish and stop without running `gh`.

Never edit an existing issue, even when the input names one or the spec's front matter records one.

## Label

The issue carries one label: `bug` when the spec's goal is to fix behaviour that is wrong today, and `enhancement` otherwise. Never give any other label.

## Publish

1. Run `gh auth status`. If it fails, ask the engineer to run `gh auth login` and then this command again, and stop.
2. List the repository's labels:
   ```sh
   gh label list --limit 1000 --json name --jq '.[].name'
   ```
   If the label is not among them, or the command fails, publish without one. Never create a label.
3. The issue's title is the text of the file's first `# ` heading, and its body is everything after that heading line, unchanged. Front matter sits above the heading, so it is never published. Read both straight from the file, so that nothing passes through your own retyping. Leave out `--label` when there is no label:
   ```sh
   awk 'f; /^# / && !f {f=1}' "<file>" | gh issue create --title "$(grep -m1 '^# ' "<file>" | cut -c3-)" --body-file - --label "<label>"
   ```
4. If that command fails, show the engineer its error and stop. Do not retry, and keep the spec. A failure can come after GitHub has already made the issue, and a retry would then make a duplicate.
5. If it succeeds, delete the spec file, report the issue's URL and its label, and stop.
