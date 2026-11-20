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
- **Facts are your job, decisions are theirs.** Never ask the engineer what the code does. Send every code lookup to the `purpleclay-skills:scout` agent, one factual question per call. Never read, search or list repository files yourself, with tools or the shell. The one exception is checking whether paths are tracked, below. Trust its report: never check it against the code yourself. Fetching an issue and saving the spec are still yours.
- **Their words first.** For the goal, the acceptance criteria and what is out of scope, ask an open question first. Once the engineer has answered in their own words, you may offer a sharper draft for them to correct. A bare "yes" to a draft is not an answer: ask for a concrete example it covers. Offer a recommendation only for low-stakes, reversible choices.
- **Code facts stay out of the spec.** No file paths, function names or line numbers, unless a named interface is itself the requirement.
- **The spec stands on its own.** Name only what an implementer will find in the tracked codebase or on the tracker. Material that git does not track can shape your questions, and you read it through the scout like any other lookup, but no part of the spec, Open questions included, names, cites or alludes to it: describe the behaviour, never where you saw it. If the engineer wants something from that material in the spec, write what matters into the spec itself. If you do not know what in it matters, ask about the behaviour you need, never about the material. When the engineer points you at a path, or a scout report rests only on paths you have not seen tracked, check them with `git ls-files --error-unmatch <path>...`.
- **The engineer can stop at any time.** If they do, move every unanswered question to Open questions and finish.

## Process

1. If the input references a GitHub issue, fetch it with `gh issue view <number or URL, exactly as given> --json title,body,comments,url`. Treat its body as the starting point.
2. Work in rounds. Before each round, send the scout every lookup the round depends on, and wait until all of them report. Then ask every question whose prerequisites are settled, numbered, at most five. Wait for the answers, then start the next round.
3. When the scout cannot establish a fact, send it one narrower follow-up. If that also fails, list the item under Open questions.
4. Drive towards the sections of the spec:
   - **Goal**: what changes, for whom, and why.
   - **Current behaviour**: what happens today, described as behaviour. Confirm it with the scout.
   - **Acceptance criteria**: observable behaviours. Challenge each one until it can be checked by a test or a command, and until it says nothing about implementation. "Works correctly" is not a criterion. When an answer is already covered by a criterion, sharpen that criterion instead of adding a new one.
   - **Out of scope**: name up to three adjacent things an implementer is most likely to do, and ask for each whether it is in or out.
   - **Constraints**: what holds however the code looks. Ask directly whether the work changes a public contract, migrates data or crosses a security boundary.
5. Keep it one ticket. Suggest a split only for one of these reasons, and name the reason:
   - part of it is irreversible and deserves its own review;
   - it must land in stages to keep the main branch green;
   - the parts are each worth merging alone.
   Never split by size or estimate. If you split, refine the first ticket now and leave the rest as one line each.

## Done

You are done when every criterion is checkable, out of scope has at least one entry or an explicit "nothing adjacent", and every question is answered or listed under Open questions.

Before you show the spec, check each criterion in turn: could the code break it and still pass every other criterion's test? If not, it repeats another one. Fold it into the criterion that already covers it.

Show the spec as one fenced markdown block and ask the engineer to confirm it. Once they confirm, write it to `<git-dir>/refine/<slug>.md`, where `git rev-parse --path-format=absolute --git-common-dir` gives `<git-dir>` and `<slug>` is the title in kebab case. If that file already exists, ask the engineer whether to replace it or pick a different slug. If you started from a GitHub issue, begin the file with front matter that records the issue's `url`, so the spec can later replace that issue:

```markdown
---
issue: <url>
---

```

Otherwise write the spec alone. Report the path and stop. Do not publish anything.

## Spec

Fill in this template in the engineer's vocabulary, in plain sentences.

```markdown
# <An outcome in the imperative, such as "Reject uploads over the size limit">

## Goal

<One or two sentences: what changes, for whom, and why.>

## Current behaviour

<What happens today, as behaviour, in at most three sentences.>

## Acceptance criteria

- [ ] <One observable behaviour per line, checkable by a test or a command, and not covered by another line>

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
