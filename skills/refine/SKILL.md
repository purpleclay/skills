---
name: refine
description: Interview the engineer about a piece of work until its goal, acceptance criteria and boundaries are sharp enough to become a ticket. Interactive only.
argument-hint: "[idea or GitHub issue]"
disable-model-invocation: true
---

# Refine

Interview the engineer until this work can be written as a ticket an agent could build without them. You are settling **what** and **where it stops**, never **how**.

Input: $ARGUMENTS

This skill needs a human. If the input contains `--auto`, say so and stop.

## Rules

- **Outcomes and boundaries only.** Do not ask how to build it. If the engineer volunteers a design, ask whether it is a real constraint (signed off, a contract others depend on). If yes, record it as a constraint. If no, say it is the implementer's call and move on.
- **Facts are your job, decisions are theirs.** Never ask the engineer what the code does. Look it up in the code yourself.
- **Their words first.** For the goal, the acceptance criteria and what is out of scope, ask an open question first. Once the engineer has answered in their own words, you may offer a sharper draft for them to correct. A bare "yes" to a draft is not an answer: ask for a concrete example it covers. Offer a recommendation only for low-stakes, reversible choices.
- **Code facts stay out of the spec.** No file paths, function names or line numbers, unless a named interface is itself the requirement.
- **The engineer can stop at any time.** If they do, move every unanswered question to Open questions and finish.

## Process

1. If the input references a GitHub issue, fetch it with `gh issue view <number or URL, exactly as given> --json title,body,comments`. Treat its body as the starting point.
2. Work in rounds. Each round, ask every question whose prerequisites are already settled, numbered, at most five. Wait for the answers, then ask the next round.
3. Drive towards the sections of the spec:
   - **Goal**: what changes, for whom, and why.
   - **Current behaviour**: what happens today, described as behaviour. Confirm it against the code yourself.
   - **Acceptance criteria**: observable behaviours. Challenge each one until it can be checked by a test or a command, and until it says nothing about implementation. "Works correctly" is not a criterion.
   - **Out of scope**: name up to three adjacent things an implementer is most likely to do, and ask for each whether it is in or out.
   - **Constraints**: what holds however the code looks. Ask directly whether the work changes a public contract, migrates data or crosses a security boundary.
4. Keep it one ticket. Suggest a split only for one of these reasons, and name the reason:
   - part of it is irreversible and deserves its own review;
   - it must land in stages to keep the main branch green;
   - the parts are each worth merging alone.
   Never split by size or estimate. If you split, refine the first ticket now and leave the rest as one line each.

## Done

You are done when every criterion is checkable, out of scope has at least one entry or an explicit "nothing adjacent", and every question is answered or listed under Open questions.

Show the spec and ask the engineer to confirm it. Once they confirm, write it to `<git-dir>/refine/<slug>.md`, where `git rev-parse --absolute-git-dir` gives `<git-dir>` and `<slug>` is the title in kebab case. If that file already exists, ask the engineer whether to replace it or pick a different slug. Report the path and stop. Do not publish anything.

## Spec

Fill in this template in the engineer's vocabulary, in plain sentences.

```markdown
# <An outcome in the imperative, such as "Reject uploads over the size limit">

## Goal

<One or two sentences: what changes, for whom, and why.>

## Current behaviour

<What happens today, as behaviour, in at most three sentences.>

## Acceptance criteria

- [ ] <One observable behaviour per line, checkable by a test or a command>

## Out of scope

- <One adjacent thing per line that an implementer must not do, or "Nothing adjacent">

## Constraints

- <One line per thing that holds however the code looks>
- Public contract change: yes / no
- Data migration: yes / no
- Security boundary: yes / no

## Open questions

- <One unanswered question per line. Leave out this heading when there are none.>
```
