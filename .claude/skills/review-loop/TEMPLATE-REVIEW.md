# REVIEW.md

What a reviewer of this repo looks at first, what past misses taught us, and what not to flag.
Reviewers read this file from the default branch (`git show origin/HEAD:REVIEW.md`), never from the
working tree or the branch under review, so a change cannot edit its own checks. Edit it in its own
commit on the default branch.

Copy this file to the repo root as `REVIEW.md`, replace every `<angle-bracket>` field, and delete
this paragraph.

## Look at first

- `<The one or two places a bug here costs the most: the write path, the auth check, the parser.>`
- `<The contract that must hold: structured results on every path, provenance stamp, no throw.>`

## Rules from past misses

Each rule names the miss behind it. A rule earns a line when the miss recurred in at least two
changes and a diff can show it (PATTERNS.md bar).

| Rule | Trigger in a diff | Miss behind it |
|---|---|---|
| `<what to check>` | `<what in the diff means this rule applies>` | `<PR, commit or incident, with date>` |

## Do not flag

- `<Known, accepted deviations, with the decision record that accepted them.>`
- `<Pre-existing issues outside the change. Mark them pre-existing; the author is not blamed.>`

## Severity for this repo

- critical: `<for example: data loss, credential exposure, a false success report>`
- high: `<...>`
- medium: `<...>`
- low: `<...>`
