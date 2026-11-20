---
name: to-ticket
description: Publish a spec saved by /refine to GitHub as an issue, either as a new issue or by replacing the issue it was refined from.
argument-hint: "[spec path] [GitHub issue]"
disable-model-invocation: true
---

# To ticket

Publish one spec from `/refine` as a GitHub issue. The engineer ran this command on purpose, and that is their approval: do not ask them to confirm the issue, and do not change a word of the spec.

Input: $ARGUMENTS

## Pick the spec

1. If the input gives a path, publish that file.
2. Otherwise, if `/refine` saved a spec earlier in this session, publish that one.
3. Otherwise list the `.md` files directly inside `<git-dir>/refine/`, where `git rev-parse --path-format=absolute --git-common-dir` gives `<git-dir>`, and ask the engineer which one to publish. If there are none, say there is nothing to publish and stop without running `gh`.

## Pick the issue

- If the input names an issue number, replace that issue in the current repository.
- Otherwise, if the spec file starts with front matter that has an `issue:` URL, replace that issue, in whichever repository the URL names.
- Otherwise create a new issue in the current repository. Never search for an existing issue to match, by title or anything else.

## Publish

1. Run `gh auth status`. If it fails, ask the engineer to run `gh auth login` and then this command again, and stop. Post nothing.
2. The issue's title is the text of the spec's first `# ` heading, and its body is everything after that heading line, unchanged. Front matter sits above the heading, so it is never published. Read both straight from the file, so that nothing passes through your own retyping:
   - New issue:
     ```sh
     awk 'f; /^# / && !f {f=1}' "<spec>" | gh issue create --title "$(grep -m1 '^# ' "<spec>" | cut -c3-)" --body-file -
     ```
   - Replacing an issue, where `<issue>` is the number given or the recorded URL:
     ```sh
     awk 'f; /^# / && !f {f=1}' "<spec>" | gh issue edit <issue> --title "$(grep -m1 '^# ' "<spec>" | cut -c3-)" --body-file -
     ```
3. If that command fails, show the engineer its error and stop. Do not retry, and keep the spec. A failure can come after GitHub has already made the issue, and a retry would then make a duplicate.
4. If it succeeds, delete the spec file, report the issue's URL, and stop.
