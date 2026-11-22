# `/to-tickets` evals

A regression suite for `/to-tickets`. Each case runs `/to-tickets` in a small throwaway git repo, as many times as its `runs` says, and passes only when every run does. The suite never reaches GitHub.

| Case                 | Runs | Smoke | Fails when                                                                                                                                                                                                                                                                                                                                                                                                                                |
| -------------------- | ---- | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `new-issue`          | 1    | yes   | given a spec that fits in one ticket, it shows a breakdown, asks anything, publishes anything but one new issue with the spec's exact title and body, or keeps the spec                                                                                                                                                                                                                                                                   |
| `typed-issue`        | 1    | yes   | it publishes anywhere but the issue number typed after the path, publishes more than once, or publishes the front matter                                                                                                                                                                                                                                                                                                                  |
| `recorded-issue`     | 1    | yes   | it publishes anywhere but the issue the spec records, in that issue's repository, publishes more than once, or publishes the front matter                                                                                                                                                                                                                                                                                                 |
| `publish-fails`      | 1    | yes   | after GitHub rejects the publish, it tries again, or deletes, moves or edits the spec                                                                                                                                                                                                                                                                                                                                                     |
| `nothing-saved`      | 1    | yes   | with no path and no saved spec, it runs `gh` at all, or doesn't say there is nothing to publish                                                                                                                                                                                                                                                                                                                                           |
| `several-saved`      | 1    | yes   | with no path, two specs `/refine` has saved as ready and one it is still refining, it publishes before the engineer picks one, doesn't list both ready specs and ask which one, or lists or mentions the spec still being refined                                                                                                                                                                                                         |
| `in-progress-path`   | 1    | yes   | given the path of a spec `/refine` is still refining, it runs `gh` at all, or doesn't say the spec is still being refined                                                                                                                                                                                                                                                                                                                 |
| `approved-breakdown` | 1    |       | after the engineer approves a breakdown of a large spec, it publishes one ticket, loses or repeats a criterion, leaves out a section, mentions another ticket, writes the tickets anywhere but a draft directory it then moves into place, doesn't replace the recorded issue with the first ticket, publishes outside that issue's repository, sets no dependencies or one on a ticket published later, or keeps the spec or its tickets |
| `revised-breakdown`  | 1    |       | after the engineer rejects a breakdown and says what is wrong, it publishes a breakdown that doesn't fix it, publishes one ticket, loses or repeats a criterion, or keeps the spec or its tickets                                                                                                                                                                                                                                         |
| `stop`               | 1    | yes   | it shows no breakdown, or, after the engineer says stop, publishes anything, saves tickets or changes the spec                                                                                                                                                                                                                                                                                                                            |
| `breakdown-fails`    | 3    |       | after GitHub rejects the second ticket of an approved breakdown, it tries again or publishes another, changes the spec, doesn't mark the second ticket as publishing before creating its issue, or doesn't keep the tickets with the first recorded as published                                                                                                                                                                          |
| `rerun`              | 1    |       | with a saved breakdown whose first ticket is published, it shows a breakdown, publishes anything but the two other tickets, links them other than the tickets record, or keeps the spec or its tickets                                                                                                                                                                                                                                    |
| `uncertain-publish`  | 1    | yes   | with a saved ticket marked as publishing but not published, it publishes or links anything before asking the engineer whether GitHub made that issue                                                                                                                                                                                                                                                                                      |

The eval runner takes one prompt per case, so a case where the engineer answers a breakdown writes the answer into the prompt, before the breakdown appears. This has two limits. When the model already has the answer, it often goes ahead without writing the table into its reply, so only `stop` checks that a breakdown is shown. And the model knows why it will reject a breakdown before it proposes one, so `revised-breakdown` checks that the engineer's correction reaches the published tickets, but can't tell a revised breakdown from a first one that already makes the correction.

## Running

There are three ways to run the suite, cheapest first. Run each from the repository root, inside `nix develop .#evals`. The runs can't reach a `git` outside the Nix store, and without one every run starts with a failing `git` command. Each prints a pass or fail for each case and a summary table, and exits non-zero if any case fails.

After every change to the skill, run the smoke cases:

```sh
PATH=".eval-bin:../.eval-bin:../../.eval-bin:$PATH" claude plugin eval . --eval-dir evals/to-tickets --tag smoke --scaffold --ablation none --allow-tools Bash Write Edit --no-publish -j 8
```

This runs the nine cases tagged `smoke` once each, for about $1.20. Each is one short session that publishes one issue at most.

Before merging, run the whole suite:

```sh
PATH=".eval-bin:../.eval-bin:../../.eval-bin:$PATH" claude plugin eval . --eval-dir evals/to-tickets --scaffold --ablation none --allow-tools Bash Write Edit --no-publish -j 8
```

This is 15 runs, for about $3.10.

Before a release, or when the model changes, run every case three times:

```sh
PATH=".eval-bin:../.eval-bin:../../.eval-bin:$PATH" claude plugin eval . --eval-dir evals/to-tickets --runs 3 --max-cost-usd 12 --scaffold --ablation none --allow-tools Bash Write Edit --no-publish -j 8
```

This is 39 runs, for about $7.70.

- `PATH=".eval-bin:../.eval-bin:../../.eval-bin:$PATH"` puts each case's stand-in `gh` ahead of the real one. The entries are relative, so inside each run they point at that run's repo, from its root or from up to two directories below it, where a run may `cd` and stay. A case stops before the run starts if `gh` resolves to anything else.
- `--tag smoke` keeps only the cases tagged `smoke`.
- `--runs 3` overrides the `runs` of every case.
- `--max-cost-usd 12` starts no new run once the estimated cost passes $12, and exits with 2 and a partial report.
- `--scaffold` runs each case's `scaffold.sh`, which builds the repo the case runs in.
- `--ablation none` skips the extra run without the plugin, since this suite does not compare `/to-tickets` with plain Claude.
- `--allow-tools Bash Write Edit` lets `/to-tickets` run `gh`, save and update tickets, and delete the spec.
- `--no-publish` keeps the report on your machine. Without it, the report is published to claude.ai.

The first run asks you to trust the plugin. Reports land in `evals/to-tickets/results/`, which git ignores.

## How often a case runs

No grader in this suite calls a judge, so the number of sessions and their length decide what a run of the suite costs. Each case sets its own number in `runs`.

A case runs three times when it has failed one run of three in a full run of the suite, and once otherwise. One has: `breakdown-fails`. A case that fails one session in three passes a single session two times in three, so one run would usually miss it. When a case that runs once starts to fail now and then, set its `runs` to 3.

A case is tagged `smoke` when it is one short session, at about $0.13. The four cases that publish a breakdown cost two to four times that and are left out: `approved-breakdown`, `revised-breakdown`, `breakdown-fails` and `rerun`.

## Layout

`gh` is the stand-in. It logs every call, keeps each published issue and each dependency, and fails publishing when a case asks it to, either from the first publish or from a later one. After every call it writes marker files that the graders look for: whether a publish went to the issue the case expects with the spec's title and body unchanged, whether the published issues hold the spec's criteria between them exactly once, whether any issue lacks a section or mentions another, and whether each dependency points at an issue published before the one it blocks. Blank lines around a body don't count, since GitHub ignores them. Each marker is described in `gh`, where it is made.

`setup.sh` builds each case's repo, whose origin is `acme/todo` on GitHub, copies the stand-in into `.eval-bin/` and saves the specs: a small one that fits in one ticket, and a large one that doesn't. It can save the large one as still being refined, for `several-saved` and `in-progress-path`. It can also save an approved breakdown of the large spec, for `rerun` and `uncertain-publish`. Each case's `scaffold.sh` sources it.

`file_exists` graders only see files a run creates, never ones a scaffold wrote. So the cases check what happened to a scaffolded spec or ticket through the commands in the trace, not the file: a Bash command that names it and deletes, moves or writes into it, in any order. Shell variables don't survive from one Bash call to the next, so a command that changes the spec has to name it.
