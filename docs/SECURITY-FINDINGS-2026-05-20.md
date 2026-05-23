# Security findings — credential surface (sibling sweep) — 2026-05-20

Second adversarial pass after the 2026-05-17 credential-surface review
([SECURITY-FINDINGS-2026-05-17.md](SECURITY-FINDINGS-2026-05-17.md)). The
1.5.1 fix addressed F-01/F-02/F-03 on `Show-Remote` / `Get-GERemoteSummary` /
`Reset-Login`, but the same root cause (regex-based URL parsing on the
read/log path) recurred in three sibling locations not swept the first time.

Method: the 2026-05-17 review found a regex-shape bug in `Reset-Login`
(F-02: `^https://(?<Host>[^/]+)/` greedily captures `user:token@host`).
Mechanical follow-up: grep the codebase for the **same regex pattern** in
**any** caller, and for **any read path** that surfaces a remote URL or
echoes its own arguments. The sweep produced three findings. All three are
fixed in 1.5.2; each carries a kill-test.

## Pattern (load-bearing lesson)

When a regex-based URL/host parse is fixed in one location, **grep the entire
codebase for the same regex shape**. A CWE-200/532 root cause rarely lives in
exactly one file. F-04/F-05/F-06 are all sibling expressions of the F-01/F-02
threat model that were not swept the first time. Save as a discipline lesson,
not a Reset-Login-specific quirk.

---

## F-04 — High — CWE-200 (Information Exposure) / CWE-532 (log exposure)

**Location:** `Private/Convert-GERemoteToSsh.ps1` (line 28 before the fix);
called from `Public/Set-Ssh.ps1:65` ahead of `Test-GERemoteUrlSafe`.

**Assumption that failed:** "An HTTPS URL passed to `Convert-GERemoteToSsh`
has a well-formed `https://host/path` shape." False — `.git/config` can carry
`https://x-access-token:ghp_REAL@github.com/o/r.git`, and the old regex
`^https://(?<Host>[^/]+)/(?<Path>.+)$` would greedily capture
`x-access-token:ghp_REAL@github.com` as the **host** (identical shape to the
F-02 bug in Reset-Login).

**Defeat:** with `.git/config` carrying that URL, `Set-Ssh` (no `-RemoteUrl`)
reads the URL, passes it to `Convert-GERemoteToSsh`, gets back a corrupt
`git@x-access-token:ghp_REAL@github.com:o/r.git`, then writes that to
`git remote set-url` — persisting the secret in `.git/config` under the new
remote spec **and** echoing it through `Invoke-GEGit`'s log step header.
`Test-GERemoteUrlSafe` runs at `Set-Ssh.ps1:68` but on the *converted* output,
not the input — the leak is already on disk by then.

**Blast radius:** a live credential persisted into `.git/config` under a new
shape and into `%LOCALAPPDATA%\GitEasy\Logs\*.log`.

**Mitigation (shipped in 1.5.2):**
1. `Convert-GERemoteToSsh` rewritten to parse with `[uri]`; throws if
   `[uri].UserInfo` is non-empty (refuses to convert URLs with embedded
   credentials — the userinfo segment is the leak vector).
2. `Set-Ssh.ps1` now calls `Test-GERemoteUrlSafe` on the **input** URL read
   from `.git/config` *before* invoking `Convert-GERemoteToSsh` — defence in
   depth so the failure surfaces at the input boundary rather than relying
   on the conversion helper's guard.

**Kill-test:** `Tests/GitEasy.AuthHardening.Tests.ps1` — "Convert-GERemoteToSsh
refuses embedded credentials" context: 5 tests covering clean conversion,
SSH passthrough, embedded-cred rejection (message must not echo the secret),
non-HTTPS rejection, and the [uri] parse behavioural lock.

---

## F-05 — Medium — CWE-200 (Information Exposure via returned object)

**Location:** `Public/Test-Login.ps1` (lines 72 and 64 before the fix).

**Assumption that failed:** "`Get-GERemoteUrl` returns a clean URL safe to
expose on a returned object." False — `Get-GERemoteUrl` reads `.git/config`
verbatim; the URL may carry `userinfo@`. `Test-Login` then placed it on
`Url = $remoteUrl` and (on failure) joined raw `ls-remote` stderr into
`Message = $result.Output -join NewLine`. Either path surfaces an embedded
secret in the returned `[PSCustomObject]` and, via PowerShell's default
formatter, on the console.

**Defeat:** `git remote add origin https://x-access-token:ghp_REAL@host/r.git`
then `Test-Login` returns `Url = 'https://x-access-token:ghp_REAL@host/r.git'`
and, on failure (any non-resolvable host), `Message` quoting the same URL
back from git's error output.

**Mitigation (shipped in 1.5.2):**
1. `Test-Login` now applies `Format-GESafeUrl` to the `Url` field before
   returning.
2. `Test-Login` pipes each output line through `Format-GESafeUrl` when
   building `Message` on the failure branch.
3. `Format-GESafeUrl` was simultaneously generalised to sanitise URLs that
   appear **mid-string** (the regex anchor was removed) so it scrubs a URL
   embedded in an error message like
   `fatal: unable to access 'https://x:tok@host/...'`. The pre-fix anchor
   matched only when the whole input was a URL.

**Kill-test:** `Tests/GitEasy.AuthHardening.Tests.ps1` — "Test-Login does not
leak embedded credentials" context: 2 tests covering the returned `Url` and
`Message` fields against a temp repo with an embedded-cred remote. Plus the
"Format-GESafeUrl mid-string and alt-scheme" context which locks the
generalised regex against mid-string URLs, `ssh://`, `git+ssh://`, IPv6
literal hosts (with and without userinfo), multi-URL strings, and `%40`.

---

## F-06 — Medium — CWE-200 / CWE-532

**Location:** `Private/Invoke-GEGit.ps1` (lines 80 and 98 before the fix).

**Assumption that failed:** "Arguments passed to `Invoke-GEGit` do not embed
secrets." False — `git remote set-url origin <url>` accepts a URL argument;
if a caller passes a URL with userinfo, the secret lands in the log step
header (`$stepText = 'git ' + ($ArgumentList -join ' ')`) and in the thrown
error message on a non-`-AllowFailure` failure. F-04 was the canonical way
to hit this surface, but any caller passing a URL-shaped argument shares
the same exposure.

**Mitigation (shipped in 1.5.2):** `Invoke-GEGit` now pipes each argument
through `Format-GESafeUrl` before joining for the step text **and** before
joining for the thrown error message. `Format-GESafeUrl` is a no-op on
arguments that are not URL-shaped, so the change is safe to apply
unconditionally. The body of stdout/stderr is **not** sanitised by the
engine — callers that surface that body to the user must apply their own
sanitisation (this constraint is documented in
[`docs/UML/README.md`](UML/README.md#takeover-findings) and the on-record
behaviour of Reset-Login, which pipes credential-helper output through
`Format-GESafeLogLine` explicitly).

**Kill-test:** `Tests/GitEasy.AuthHardening.Tests.ps1` — "Invoke-GEGit
sanitises URL-shaped args" context: 1 test driving `git remote set-url` with
an embedded-cred URL against a non-existent remote, asserting the thrown
error message contains neither the token nor the `user:` boundary.

---

## Adjacent hardening (not new findings; shipped alongside)

- **`Reset-Login` cmdkey path now checks exit codes** before claiming success.
  The original code set `$clearedSomething = $true` unconditionally when
  `cmdkey.exe` existed on the machine, regardless of whether any delete
  actually succeeded. Same "silent success" shape as F-02; not a credential
  leak, but a correctness drift worth fixing in the same pass.
- **`Format-GESafeLogLine` now also redacts `Proxy-Authorization` headers.**
  The previous regex matched only the bare `authorization` alternation, so
  `Proxy-Authorization: ...` would slip through. The line-shape anchor
  remains by design — narrative text containing `password=foo` mid-sentence
  is intentionally left alone.

## Not changed (named, not silently dropped)

- **`Invoke-GEGit` body sanitisation.** The engine still emits raw stdout/
  stderr in the log body and the thrown error body. Architectural decision:
  callers know best whether their git output may carry credentials; forcing
  scrub at the engine would obscure legitimate output for non-credential
  commands. Reset-Login pipes credential-helper output through
  `Format-GESafeLogLine` explicitly; future callers that drive credential
  helpers must do the same. Documented as Takeover finding #3 in
  `docs/UML/README.md`.
- **`Invoke-GEGit` global-CWD mutation.** Still not thread-safe. Out of scope
  for this credential pass; tracked in `Wiki/Roadmap.md`.

## Trust-boundary diagram

```
.git/config (untrusted-region input)
    │
    ▼
Get-GERemoteUrl (read; returns raw)
    │
    ├─► Set-Token / Set-Ssh INPUT path ─► Test-GERemoteUrlSafe (rejects userinfo, non-HTTPS/SSH)
    │       │
    │       └─► Set-Ssh: Convert-GERemoteToSsh ─► Test-GERemoteUrlSafe (twice for defence)
    │
    └─► READ path (Show-Remote → Get-GERemoteSummary, Reset-Login, Test-Login)
            │
            ▼
        Format-GESafeUrl (strips userinfo from URLs anywhere in the string)
            │
            ▼
        Returned PSCustomObject / log line / thrown error message
```

`Test-GERemoteUrlSafe` is input-only by design; `Format-GESafeUrl` is the
output-side equivalent; `Format-GESafeLogLine` redacts credential-bearing
log lines (`password=` / `token=` / `Authorization:` / `Proxy-Authorization:`
etc.) at the log boundary. The three helpers form a deliberate
input-guard / output-sanitiser / log-sanitiser triad.
