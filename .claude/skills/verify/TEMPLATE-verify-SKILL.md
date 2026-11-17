---
name: verify
description: Use before every commit in this repo and before any claim that a change works. Boots <PRODUCT>, drives one real flow, and says what to inspect. The repo's smoke-test harness, per the global verify skill (C:\Users\keith\.claude\skills\verify\SKILL.md).
---

# Verify <PRODUCT>

Copy this file to `<repo>\.claude\skills\verify\SKILL.md`, replace every `<angle-bracket>` field, and
delete this paragraph. Every section stays, even when its answer is "none".

## Where to run from

Run everything below from `<repo root, absolute path>`. If the shell is anywhere else, say so and
move first (CLAUDE.md section 9).

## Cheap checks first

In this order. Stop at the first failure.

1. Static analysis: `<command>`. Success looks like: `<for example: 0 warnings, 0 errors>`.
2. Build: `<command, or "none: PowerShell module">`. Success looks like: `<text>`.
3. Unit tests: `<command, for example Tools\Invoke-<Prefix>Pester.ps1>`. Success looks like:
   `<for example: Passed: N Failed: 0>`.

## Boot

`<How the product starts for a check. For a module: Import-Module .\<Name>.psd1 -Force. For a
service: the local run command and the port. For a UI: the launcher and what window appears.>`

Success looks like: `<text>`.

## Drive one real flow

The flow a user would recognise, end to end:

1. `<step>`
2. `<step>`
3. `<step>`

Success looks like: `<the observable result: output text, a status code, a file that now exists,
a screenshot that shows X>`.

## Inspect

- `<what to read afterwards: a log path, a result object, a database row, a screenshot>`
- `<what a regression would look like here>`

## Known slow or fragile parts

`<Anything that takes more than a minute or needs a live environment, and what to do instead when it
is not available. "None" is a valid answer.>`

## What this harness does not prove

`<The honest limits. For example: PS 5.1 compatibility (only runs on 7), behaviour against a real AD,
the installed-from-PSGallery path. These go in the Not verified block of the closeout.>`

## Trailer shape for this repo

```
Verified: <runner> N/N; verify: <flow name> on <target> saw <result>
```
