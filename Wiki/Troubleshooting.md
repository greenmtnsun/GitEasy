# Troubleshooting

## LF/CRLF warnings are not conflicts

Use this to check for real unresolved merge conflicts:

```powershell
git diff --name-only --diff-filter=U
```

## Git writes normal progress to stderr

GitEasy should treat Git success or failure based on process exit code, not stderr text alone.

## Clean branch can still be ahead

A clean working tree can still have unpushed commits.

Use:

```powershell
git status -sb
```
