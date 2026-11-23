# `/refine` evals

A regression suite for `/refine`. Each case runs `/refine` in a small throwaway Go repo, as many times as its `runs` says, and passes only when every run does.

| Case                   | Runs | Smoke | Fails when                                                                                                                                                                                                                                                                                                 |
| ---------------------- | ---- | ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `auto-flag`            | 1    |       | `/refine --auto` does anything other than say it needs a human and stop                                                                                                                                                                                                                                    |
| `confirmed-spec`       | 1    | yes   | confirming a ready spec does not end with one line naming its title and `/to-tickets`, or the ending shows a file path or another command                                                                                                                                                                  |
| `declined-spec`        | 1    | yes   | picking a ready spec and declining to change it does not end with one line naming its title and `/to-tickets`, shows a file path or another command, or starts an interview                                                                                                                                |
| `early-stop`           | 1    | yes   | stopping an interview early does not end with one line naming the spec by its title and saying `/refine` with no input picks it up again, or the ending shows a file path or another command                                                                                                               |
| `first-round`          | 1    | yes   | the first round waits for the scout before asking, asks more than three questions, has a question that lacks its number, label or what it decides or strays from the layout in the skill, or is asked without saving the spec as in progress, with the round's questions open and recorded as not answered |
| `no-saved-specs`       | 3    |       | with no input and no saved specs, it shows a table or does anything but ask what to refine                                                                                                                                                                                                                 |
| `no-split`             | 3    |       | it proposes splitting large work into several tickets, or leaves part of it out of the spec                                                                                                                                                                                                                |
| `proposes-constraints` | 3    |       | it asks whether the work changes a public contract instead of proposing an answer with a reason                                                                                                                                                                                                            |
| `prose-reply`          | 1    |       | a reply answered out of order is read back under the wrong questions, or a skipped question is not marked and asked again                                                                                                                                                                                  |
| `publishing-spec`      | 1    | yes   | picking a ready spec that `/to-tickets` has started publishing doesn't point to `/to-tickets`, changes the spec or starts an interview                                                                                                                                                                     |
| `reads-idea-back`      | 1    |       | the first round asks for the goal instead of reading the idea back                                                                                                                                                                                                                                         |
| `repeated-criteria`    | 3    |       | an acceptance criterion repeats another                                                                                                                                                                                                                                                                    |
| `resume`               | 1    | yes   | picking an in-progress spec does not recap its last round, asks an answered question again, skips the unanswered one, reuses its number, or doesn't save to the spec it picked up                                                                                                                          |
| `saved-specs-table`    | 1    | yes   | with no input, it does not list the saved specs in a table with their state, most recent first, or starts an interview                                                                                                                                                                                     |
| `spec-from-lookups`    | 1    | yes   | the main conversation reads repository files instead of asking the scout, or the spec names a file in the repository, which goes stale as the code moves                                                                                                                                                   |
| `untracked-material`   | 1    |       | the spec names, cites or alludes to files that git does not track                                                                                                                                                                                                                                          |

## Running

There are three ways to run the suite, cheapest first. Run each from the repository root, inside `nix develop .#evals`. The runs can't reach a `git` outside the Nix store, and without one every run starts with a failing `git` command. Each prints a pass or fail for each case and a summary table, and exits non-zero if any case fails.

After every change to the skill, run the smoke cases:

```sh
claude plugin eval . --eval-dir evals/refine --tag smoke --scaffold --ablation none --allow-tools Bash Write Edit --no-publish -j 4
```

This runs the eight cases tagged `smoke` once each, for about $1.45. Their graders are all patterns, so nothing calls the judge and the same transcript always gets the same verdict.

Before merging, run the whole suite:

```sh
claude plugin eval . --eval-dir evals/refine --scaffold --ablation none --judge-model sonnet --allow-tools Bash Write Edit --no-publish -j 4
```

This is 24 runs, for about $5.75.

Before a release, or when the model changes, run every case three times:

```sh
claude plugin eval . --eval-dir evals/refine --runs 3 --max-cost-usd 15 --scaffold --ablation none --judge-model sonnet --allow-tools Bash Write Edit --no-publish -j 4
```

This is 48 runs, for about $11.55.

- `--tag smoke` keeps only the cases tagged `smoke`.
- `--runs 3` overrides the `runs` of every case.
- `--max-cost-usd 15` starts no new run once the estimated cost passes $15, and exits with 2 and a partial report.
- `--scaffold` runs each case's `scaffold.sh`, which builds the repo the case runs in.
- `--ablation none` skips the extra run without the plugin, since this suite does not compare `/refine` with plain Claude.
- `--allow-tools Bash Write Edit` lets `/refine` find, read and save its specs.
- `--judge-model sonnet` grades the judgement calls with Sonnet. The default, Haiku, failed specs that were fine.
- `--no-publish` keeps the report on your machine. Without it, the report is published to claude.ai.

The first run asks you to trust the plugin. Reports land in `evals/refine/results/`, which git ignores.

## How often a case runs

A session costs between $0.11 and $0.43, so the number of sessions decides what a run of the suite costs. Each case sets its own number in `runs`.

A case runs three times when it has failed one run of three in a full run of the suite, and once otherwise. Four cases have: `no-saved-specs`, `no-split`, `proposes-constraints` and `repeated-criteria`. A case that fails one session in three passes a single session two times in three, so one run would usually miss it.

When a case that runs once starts to fail now and then, set its `runs` to 3. When a case that runs three times has passed every run for a few weeks, set it back to 1.

A case is tagged `smoke` when none of its graders calls the judge and one session shows whether it passes.

## Layout

`fixture.sh` writes a small Go todo CLI. Nothing compiles or runs it; the scout only reads it. `scaffold.sh` commits that project to a fresh git repo, and most cases link their own `scaffold.sh` to it. `untracked-material` has its own `scaffold.sh`, which runs the shared one and then adds notes that git does not track.

`saved-specs.sh` runs `scaffold.sh`, then saves two specs: one stopped after its second round, with one question of that round unanswered, and an older one saved before `/refine` recorded state. `saved-specs-table`, `resume` and `declined-spec` link their `scaffold.sh` to it. `publishing-spec` runs it, then saves a breakdown of the ready spec whose first ticket is published. `early-stop` runs it, then records in the in-progress spec the third round that its history has asked.

`prose-reply`, `proposes-constraints`, `resume`, `publishing-spec`, `declined-spec`, `early-stop` and `confirmed-spec` test a reply to something `/refine` has already said. Each resumes `history.jsonl`, a conversation in which `/refine` has already asked its first round, or has shown the table of saved specs for `resume`, `publishing-spec` and `declined-spec`, a resumed round for `early-stop`, or the finished spec for `confirmed-spec`. The case's prompt is the engineer's reply. The history holds no skill text, so the reply starts with `/refine` to load the current skill.

One case checks several things when one session can show all of them. `first-round` holds every check on the first round that a pattern can make: when the round is asked, how it is laid out and what is saved. `reads-idea-back` has the same prompt and holds the one check on that round that needs the judge, so that `first-round` can stay in the smoke cases. `spec-from-lookups` checks both how the code is looked up and what the spec says about it. A case stays on its own when its prompt sets a trap that would change what the others see, as `no-split`, `repeated-criteria` and `untracked-material` do.

Runs can't write under `.git/`, so every save `/refine` tries is refused. `first-round` checks the save it tries, in the trace, and the other cases run on regardless. `confirmed-spec` needs its save to succeed, since a refused save changes how `/refine` ends, so its `scaffold.sh` puts the git directory at `.gitdir` instead of `.git`.

`/refine` runs its lookups in the background and answers each one that reports during a round with a single line, so the last message is rarely the round itself. Cases that grade a round read it from the trace.
