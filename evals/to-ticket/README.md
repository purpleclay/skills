# `/to-ticket` evals

A regression suite for `/to-ticket`. Each case runs `/to-ticket` once in a small throwaway git repo. The suite never reaches GitHub.

| Case               | Fails when                                                                                                                                                                                                                        |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `new-issue`        | given a spec that adds behaviour, it asks anything, publishes anything but one new issue labelled `enhancement` with the spec's exact title and body, or keeps the spec                                                           |
| `bug-label`        | given a spec that fixes wrong behaviour, it publishes anything but one new issue labelled `bug` alone                                                                                                                             |
| `missing-label`    | given a spec that fixes wrong behaviour in a repository with no `bug` label, it publishes anything but one new issue with no label, or creates a label                                                                            |
| `publish-fails`    | after GitHub rejects the publish, it tries again, or deletes, moves or edits the spec                                                                                                                                             |
| `in-progress-path` | given the path of a spec `/refine` is still refining, it runs `gh` at all, or doesn't say the spec is still being refined                                                                                                         |
| `several-saved`    | with no path, two specs `/refine` has saved as ready and one it is still refining, it publishes before the engineer picks one, doesn't list both ready specs and ask which one, or lists or mentions the spec still being refined |
| `nothing-saved`    | with no path and no saved spec, it runs `gh` at all, or doesn't say there is nothing to publish                                                                                                                                   |

## Running

Run from the repository root, inside `nix develop .#evals`. The runs can't reach a `git` outside the Nix store, and without one every run starts with a failing `git` command.

```sh
PATH=".eval-bin:../.eval-bin:../../.eval-bin:$PATH" claude plugin eval . --eval-dir evals/to-ticket --scaffold --ablation none --allow-tools Bash Write Edit --no-publish -j 8
```

This is seven short sessions, for about $0.90. It prints a pass or fail for each case and a summary table, and exits non-zero if any case fails.

- `PATH=".eval-bin:../.eval-bin:../../.eval-bin:$PATH"` puts each case's stand-in `gh` ahead of the real one. The entries are relative, so inside each run they point at that run's repo, from its root or from up to two directories below it, where a run may `cd` and stay. A case stops before the run starts if `gh` resolves to anything else.
- `--scaffold` runs each case's `scaffold.sh`, which builds the repo the case runs in.
- `--ablation none` skips the extra run without the plugin, since this suite does not compare `/to-ticket` with plain Claude.
- `--allow-tools Bash Write Edit` lets `/to-ticket` run `gh` and delete the spec.
- `--no-publish` keeps the report on your machine. Without it, the report is published to claude.ai.

The first run asks you to trust the plugin. Reports land in `evals/to-ticket/results/`, which git ignores.

## Layout

`gh` is the stand-in. It logs every call, lists the repository's labels, and fails publishing when a case asks it to. For each publish it writes marker files that the graders look for: whether it was a new issue with the spec's title and body unchanged, which labels it gave, and whether a label was created. Each marker is described in `gh`, where it is made.

`setup.sh` builds each case's repo, whose origin is `acme/todo` on GitHub, copies the stand-in into `.eval-bin/` and saves the specs: one that adds due dates, or one that fixes a crash on an empty todo file. It can also save a spec as still being refined, for `several-saved` and `in-progress-path`. Each case's `scaffold.sh` sources it.

`file_exists` graders only see files a run creates, never ones a scaffold wrote. So the cases check what happened to a scaffolded spec through the commands in the trace, not the file: a Bash command that names it and deletes, moves or writes into it, in any order.
