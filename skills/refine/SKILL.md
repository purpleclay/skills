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
- **Their words first.** For the goal, the acceptance criteria and what is out of scope, ask an open question first. When `/refine` starts with an idea or an issue, that already gives the goal in their words: make it the first question, reading the idea, or the issue body, back as the goal for the engineer to correct, and never ask for the goal as an open question. Once the engineer has answered in their own words, you may offer a sharper draft for them to correct. A bare "yes" to a draft is not an answer: ask for a concrete example it covers. Offer a recommendation only for low-stakes, reversible choices.
- **Answers arrive as prose.** The engineer may type or dictate a reply, answer in any order and leave out the numbers. Work out which part of the reply answers which question. Open the message that asks the next round, or shows the spec, with a table with the columns `Question` and `What I took from your reply`, with one row for every question of the last round, under its number and label. Write "Not answered" for a question the reply did not answer, and "Not yet checkable:" followed by what is missing for an answer too vague to check. Ask each of those again in the next round, under the same number and label.
- **Code facts stay out of the spec.** No file paths, function names or line numbers, unless a named interface is itself the requirement.
- **The spec stands on its own.** Name only what an implementer will find in the tracked codebase or on the tracker. Material that git does not track can shape your questions, and you read it through the scout like any other lookup, but no part of the spec, Open questions included, names, cites or alludes to it: describe the behaviour, never where you saw it. If the engineer wants something from that material in the spec, write what matters into the spec itself. If you do not know what in it matters, ask about the behaviour you need, never about the material. When the engineer points you at a path, or a scout report rests only on paths you have not seen tracked, check them with `git ls-files --error-unmatch <path>...`.
- **The engineer can stop at any time.** If they do, move every unanswered question to Open questions and finish.

## Process

1. If the input references a GitHub issue, fetch it with `gh issue view <number or URL, exactly as given> --json title,body,comments,url`. Treat its body as the starting point.
2. Work in rounds, so the engineer answers while the scout researches. In each round's message, after the table of the last round's answers, if there is one, say what the lookups that reported since the last round found. Then ask at most three questions whose prerequisites are settled, questions asked again counting towards the three, laid out as in **Questions** below. Number questions across the whole interview, so a number always means the same question. In the same turn, send the scout every lookup that later rounds depend on, with `run_in_background: true`, and ask without waiting for them to report. Never ask a question before the lookups it depends on have reported. If every remaining question depends on a lookup that is still running, wait for it instead of asking. When a lookup reports while you wait for the engineer's answers, reply in one short line that you are waiting for their answers. Do not repeat the questions or say what it found: keep that for the next round. Wait for the answers, then start the next round.
3. When the scout cannot establish a fact, send it one narrower follow-up. If that also fails, list the item under Open questions.
4. Drive towards the sections of the spec:
   - **Goal**: what changes, for whom, and why.
   - **Current behaviour**: what happens today, described as behaviour. Confirm it with the scout.
   - **Acceptance criteria**: observable behaviours. Challenge each one until it can be checked by a test or a command, and until it says nothing about implementation. "Works correctly" is not a criterion. When an answer is already covered by a criterion, sharpen that criterion instead of adding a new one.
   - **Out of scope**: name up to three adjacent things an implementer is most likely to do, and ask for each whether it is in or out.
   - **Constraints**: what holds however the code looks. For whether the work changes a public contract, migrates data or crosses a security boundary, ask the scout what you need to judge it, then propose yes or no for each, with a one-line reason based on what the code does, and ask the engineer to confirm or correct them. The spec records the engineer's answer.
5. Keep it one spec. However large the work, refine all of it and never propose splitting it into several tickets or specs: `/to-tickets` splits it when it publishes.

## Questions

Lay out every question like this, with a blank line between its parts: its number and a label of two or three words, never one, in bold, then the question, then one line in italics on what the answer decides. Between neighbouring questions, put a line of 80 `─` characters, with a blank line either side. Put none before the first question or after the last.

```markdown
**2 · Done todos**

Once a todo is done, should it still appear in `todo list`?

*Decides: whether done todos stay in the list.*
```

## Done

You are done when every criterion is checkable, out of scope has at least one entry or an explicit "nothing adjacent", and every question is answered or listed under Open questions.

Before you show the spec, check each criterion in turn: could the code break it and still pass every other criterion's test? If not, it repeats another one. Fold it into the criterion that already covers it.

Wait for every lookup to report, then show the spec as one fenced markdown block and ask the engineer to confirm it. Once they confirm, write it to `<git-dir>/refine/<slug>.md`, where `git rev-parse --path-format=absolute --git-common-dir` gives `<git-dir>` and `<slug>` is the title in kebab case. If that file already exists, ask the engineer whether to replace it or pick a different slug. If you started from a GitHub issue, begin the file with front matter that records the issue's `url`, so the spec can later replace that issue:

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
