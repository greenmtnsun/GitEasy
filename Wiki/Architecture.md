# Architecture

GitEasy uses a small public command surface backed by private helpers.

## Layout

| Path | Purpose |
| --- | --- |
| `GitEasy.psd1` | Module manifest |
| `GitEasy.psm1` | Root module loader |
| `Public\` | User-facing commands |
| `Private\` | Internal helper logic |
| `Tests\` | Pester tests |
| `Tools\` | Development tools |

## Design Rules

- Prefer GitEasy commands before raw Git commands.
- Public commands should remain stable and plain-English.
- Private helpers should use the GE prefix.
- Fail fast on unsafe repository states.
- Judge native Git success by exit code, not stderr text.
- Avoid UTF-8 BOM in generated files and commit message temp files.
