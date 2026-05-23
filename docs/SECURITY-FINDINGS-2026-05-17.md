# Security findings — credential surface — 2026-05-17

Adversarial review of GitEasy's credential / remote-auth surface, prompted by
the 2026-05-15 UML takeover note ("credential-path coverage thin — Reset-Login
~23%, Show-Remote ~36% — and no formal security review on record").

Method: trace untrusted inputs → name the trust boundary → name the assumption
each safeguard depends on → try to defeat it. All three findings below were
fixed in the same change that records this note; each carries a kill-test.

## Trust boundary

`Test-GERemoteUrlSafe` rejects credential-embedding URLs — but it is called in
exactly two places, **both input** (`Set-Token.ps1:49`, `Set-Ssh.ps1:68`). The
**read path** (`Get-GERemoteUrl`, `Get-GERemoteSummary`, `Show-Remote`,
`Reset-Login`) reads whatever is already in `.git/config` and surfaces it to
the console and the on-disk diagnostic log with no guard and no redaction.
`.git/config` is an **untrusted-region input**: it is written by clone-with-
credentials, CI tooling, other software, or a hostile repository — not only by
GitEasy. The guard was on the wrong side of the boundary for the read path.

---

## F-01 — High — CWE-200 (Information Exposure) / CWE-532 (log exposure)

**Location:** `Private/Get-GERemoteSummary.ps1`, `Public/Show-Remote.ps1`,
`Public/Reset-Login.ps1`, `Private/Get-GERemoteUrl.ps1`.

**Assumption that failed:** "An unsafe URL can only enter via Set-Token /
Set-Ssh, which validate it." False — the read path never validates or redacts.

**Defeat:** with `.git/config` remote
`https://x-access-token:ghp_REAL@github.com/o/r.git`:
- `Show-Remote` returned `Url` containing the live PAT, and rendered it to the
  console (and through `Format/GitEasy.format.ps1xml`).
- `Reset-Login`'s old host regex `^https://(?<Host>[^/]+)/` captured
  `x-access-token:ghp_REAL@github.com` as the "host", which `Add-GELogStep`
  then wrote verbatim — together with `git credential` stdout — to
  `%LOCALAPPDATA%\GitEasy\Logs\*.log` (plaintext, `AppendAllText`, ~30-day
  retention).

**Blast radius:** a live credential at rest on disk and in screen scrollback /
CI logs.

**Mitigation (shipped):** `Private/Format-GESafeUrl.ps1` strips the
`userinfo@` segment from a `scheme://` authority (leaves clean URLs and the
scp-like SSH form untouched). Applied in `Get-GERemoteSummary` (the Show-Remote
feed) and to the Reset-Login error message.

**Kill-test:** `GitEasy.AuthHardening.Tests.ps1` — "redacts an embedded
token from the reported Url"; "the failure log for a non-HTTPS embedded-cred
remote contains no secret"; plus the `Format-GESafeUrl` unit context.

---

## F-02 — Medium — correctness + contributes to F-01

**Location:** `Public/Reset-Login.ps1` host parse.

**Assumption that failed:** `^https://(?<Host>[^/]+)/` extracts the host.
False for `https://user:tok@host/…` — `[^/]+` greedily captured
`user:tok@host`.

**Consequence:** `git credential reject` was sent the wrong host, so the
saved login was **silently not cleared** (Reset-Login reported success while
doing nothing useful), and the embedded secret rode into the log (F-01).

**Mitigation (shipped):** parse with `[uri]`; require `.Scheme -eq 'https'`
and a non-empty `.Host`. `[uri]` places `user:tok@` in `UserInfo`, never in
`.Host`.

**Kill-test:** `GitEasy.AuthHardening.Tests.ps1` — "the [uri] parse the
F-02 fix relies on yields the bare host, not user:token@host". The host value
on the *success* path (past the parse) is review-verified, not executed in a
test, because running Reset-Login that far drives the operator's real
credential store — out of bounds for an automated test.

---

## F-03 — Low — CWE-200 (Information Exposure via logs)

**Location:** `Public/Reset-Login.ps1` — the `Add-GELogStep` calls that
recorded raw `git credential reject` / `git credential-manager erase` stdout.

**Assumption that failed:** "credential-helper output is innocuous." Helper-
dependent — the git credential protocol can echo `password=` / `secret=` /
`token=` / `Authorization:` lines.

**Mitigation (shipped):** `Private/Format-GESafeLogLine.ps1` replaces the
value of any credential-bearing line with `[redacted]` (keeps the key for
diagnostics). Piped into both `Add-GELogStep` calls in Reset-Login.

**Kill-test:** `GitEasy.AuthHardening.Tests.ps1` — the
`Format-GESafeLogLine` unit context (redacts password/secret/token/bearer/
Authorization, case-insensitive, keeps non-sensitive protocol lines). The
wiring into Reset-Login is review-verified (the `| Format-GESafeLogLine` in
both `Add-GELogStep` calls).

---

## Not changed (named, not silently dropped)

- `Test-GERemoteUrlSafe` remains input-only by design; the read path is now
  covered by `Format-GESafeUrl`. The two are deliberately separate (input
  guard vs output sanitiser).
- The other 2026-05-15 takeover findings (Invoke-GEGit raw-git contract not
  type-enforced; Invoke-GEGit global-CWD mutation not reentrant; the HELD
  wiki-scripts → tools/ refactor) are out of scope for this credential pass
  and remain tracked in `Wiki/Known-Bugs-and-Fixes.md` / `Wiki/Roadmap.md`.
