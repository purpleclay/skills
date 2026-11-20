# `/to-ticket` evals

A regression suite for `/to-ticket`. Each case runs `/to-ticket` three times in a small throwaway git repo, and passes only when all three runs do. The suite never reaches GitHub.

| Case             | Fails when                                                                                                                                |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `new-issue`      | given only a spec path, it publishes anything but one new issue with the spec's exact title and body, or keeps the spec                   |
| `typed-issue`    | it publishes anywhere but the issue number typed after the path, publishes more than once, or publishes the front matter                  |
| `recorded-issue` | it publishes anywhere but the issue the spec records, in that issue's repository, publishes more than once, or publishes the front matter |
| `publish-fails`  | after GitHub rejects the publish, it tries again, or deletes, moves or edits the spec                                                     |
| `nothing-saved`  | with no path and no saved spec, it runs `gh` at all, or doesn't say there is nothing to publish                                           |
| `several-saved`  | with no path and two saved specs, it publishes before the engineer picks one, or doesn't list both and ask which one                      |

## Running

From the repository root:

```sh
PATH=".eval-bin:$PATH" claude plugin eval . --eval-dir evals/to-ticket --scaffold --ablation none --allow-tools Bash --no-publish -j 6
```

It prints a pass or fail for each case and a summary table, and exits non-zero if any case fails. A full run takes under a minute and costs about $1.90.

- `PATH=".eval-bin:$PATH"` puts each case's stand-in `gh` ahead of the real one. The entry is relative, so inside each run it points at that run's repo. A case stops before the run starts if `gh` resolves to anything else.
- `--scaffold` runs each case's `scaffold.sh`, which builds the repo the case runs in.
- `--ablation none` skips the extra run without the plugin, since this suite does not compare `/to-ticket` with plain Claude.
- `--allow-tools Bash` lets `/to-ticket` run `gh` and delete the spec.
- `--no-publish` keeps the report on your machine. Without it, the report is published to claude.ai.

The first run asks you to trust the plugin. Reports land in `evals/to-ticket/results/`, which git ignores.

## Layout

`gh` is the stand-in. It logs every call, fails every publish when a case asks it to, and records whether a publish went to the issue the case expects with the spec's title and body unchanged. Blank lines around the body don't count, since GitHub ignores them. `setup.sh` builds each case's repo, whose origin is `acme/todo` on GitHub, copies the stand-in into `.eval-bin/` and saves the specs. Each case's `scaffold.sh` sources it.

`file_exists` graders only see files a run creates, never ones a scaffold wrote. So the cases check what happened to the spec through the commands in the trace, not the file: a Bash command that names the spec and deletes, moves or writes into it, in any order. Shell variables don't survive from one Bash call to the next, so a command that changes the spec has to name it.
