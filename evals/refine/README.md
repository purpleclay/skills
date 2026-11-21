# `/refine` evals

A regression suite for `/refine`. Each case runs `/refine` three times in a small throwaway Go repo, and passes only when all three runs do.

| Case                   | Fails when                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `auto-flag`            | `/refine --auto` does anything other than say it needs a human and stop                                                   |
| `no-file-paths`        | the spec names a file in the repository, which goes stale as the code moves                                               |
| `no-split`             | it proposes splitting large work into several tickets, or leaves part of it out of the spec                               |
| `proposes-constraints` | it asks whether the work changes a public contract instead of proposing an answer with a reason                           |
| `prose-reply`          | a reply answered out of order is read back under the wrong questions, or a skipped question is not marked and asked again |
| `question-format`      | the first round asks more than three questions, or a question lacks its number, label or what it decides                  |
| `repeated-criteria`    | an acceptance criterion repeats another                                                                                   |
| `scout-lookups`        | the main conversation reads repository files instead of asking the scout                                                  |
| `untracked-material`   | the spec names, cites or alludes to files that git does not track                                                         |

## Running

From the repository root:

```sh
claude plugin eval . --eval-dir evals/refine --scaffold --ablation none --judge-model sonnet --no-publish -j 4
```

It prints a pass or fail for each case and a summary table, and exits non-zero if any case fails. A full run takes about four minutes and costs about $4.10.

- `--scaffold` runs each case's `scaffold.sh`, which builds the repo the case runs in.
- `--ablation none` skips the extra run without the plugin, since this suite does not compare `/refine` with plain Claude.
- `--judge-model sonnet` grades the judgement calls with Sonnet. The default, Haiku, failed specs that were fine.
- `--no-publish` keeps the report on your machine. Without it, the report is published to claude.ai.

The first run asks you to trust the plugin. Reports land in `evals/refine/results/`, which git ignores.

## Layout

`fixture.sh` writes a small Go todo CLI. Nothing compiles or runs it; the scout only reads it. `scaffold.sh` commits that project to a fresh git repo, and most cases link their own `scaffold.sh` to it. `untracked-material` has its own `scaffold.sh`, which runs the shared one and then adds notes that git does not track.

`prose-reply` and `proposes-constraints` test a reply to a round of questions. Each resumes `history.jsonl`, a conversation in which `/refine` has already asked its first round, and the case's prompt is the engineer's reply. The history holds no skill text, so the reply starts with `/refine` to load the current skill.
