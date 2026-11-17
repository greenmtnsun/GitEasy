// =============================================================================
// Script  : vale-prose-gate.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of vale-prose-gate.ps1
//                            (2026-10-23, 2026-11-12) for the portable kit.
//                            PostToolUse (Write|Edit|MultiEdit): pass-2 prose
//                            lint. Runs Vale (Microsoft Writing Style Guide)
//                            on markdown files as they are written and feeds
//                            warning-level findings back via exit 2. Pairs
//                            with the humanized-writing skill (pass 1) and
//                            CLAUDE.md section 10. Cheap-first, FAIL-OPEN: no
//                            vale on PATH means exit 0 silently. Skips
//                            non-markdown, .claude internals, scratchpad,
//                            Temp and node_modules. A finding blocks once per
//                            session per file: shown findings are remembered
//                            in <stateDir>/vale-seen/<session>.txt
//                            (VALE_GATE_SEEN_DIR overrides, for tests). A
//                            Vale.Spelling finding whose word matches an entry
//                            in the Shared accept list is dropped
//                            (VALE_GATE_ACCEPT_FILE overrides the path).
// =============================================================================
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'vale-prose-gate';
const SHOW_LIMIT = 15;

// Steps (findVale):
//   1. On Windows, prefer the winget install path under LOCALAPPDATA when it exists.
//   2. Otherwise return 'vale' and let PATH resolve it; the caller treats a spawn error as "no Vale".
function findVale() {
  if (process.platform === 'win32' && process.env.LOCALAPPDATA) {
    const winget = path.join(process.env.LOCALAPPDATA, 'Microsoft', 'WinGet', 'Packages', 'errata-ai.Vale_Microsoft.Winget.Source_8wekyb3d8bbwe', 'vale.exe');
    if (fs.existsSync(winget)) return winget;
  }
  return 'vale';
}

// Steps (runVale):
//   1. Run vale --output=line --minAlertLevel=warning <file>, stderr discarded.
//   2. Return null when vale is absent (spawn error) or times out; else the non-empty output lines (vale exits 1 when it has findings).
function runVale(exe, file) {
  const r = spawnSync(exe, ['--output=line', '--minAlertLevel=warning', file], { encoding: 'utf8', timeout: 60000, windowsHide: true, stdio: ['ignore', 'pipe', 'ignore'] });
  if (r.error || r.status === null) return null;
  return String(r.stdout || '').split(/\r?\n/).filter(l => l.trim());
}

// Steps (loadAccept):
//   1. VALE_GATE_ACCEPT_FILE, else <home>/.vale/styles-clean/config/vocabularies/Shared/accept.txt.
//   2. Each non-blank line becomes an anchored regex; a line that does not compile is skipped.
function loadAccept() {
  const acceptFile = process.env.VALE_GATE_ACCEPT_FILE || path.join(os.homedir(), '.vale', 'styles-clean', 'config', 'vocabularies', 'Shared', 'accept.txt');
  if (!fs.existsSync(acceptFile)) return null;
  const out = [];
  for (const entry of fs.readFileSync(acceptFile, 'utf8').split(/\r?\n/)) {
    const e = entry.trim();
    if (!e) continue;
    try { out.push(new RegExp(`^(?:${e})$`)); } catch { }
  }
  return out;
}

// Steps (dropAccepted):
//   1. Keep every finding that is not a Vale.Spelling "Did you really mean 'word'?" line.
//   2. Drop a spelling finding whose word matches any accept-list regex.
function dropAccepted(findings, accept) {
  return findings.filter(f => {
    const m = /:\d+:\d+:Vale\.Spelling:Did you really mean '([^']+)'\?\s*$/.exec(f);
    if (!m) return true;
    return !accept.some(rx => rx.test(m[1]));
  });
}

// Steps (seenFileFor):
//   1. No session id means no memory: return null, so every finding blocks as before.
//   2. VALE_GATE_SEEN_DIR, else <stateDir>/vale-seen; file name is the session id with non-word chars replaced by _.
function seenFileFor(p) {
  const session = p.session_id === undefined || p.session_id === null ? '' : String(p.session_id);
  if (!session) return null;
  const seenDir = process.env.VALE_GATE_SEEN_DIR || path.join(C.stateDir(p), 'vale-seen');
  return path.join(seenDir, session.replace(/[^\w-]/g, '_') + '.txt');
}

// Steps (keyFor):
//   1. A finding is keyed by file (lower-cased), rule, message and the trimmed text of its line, so it survives line shifts from edits above it.
//   2. A line that does not parse as file:line:col:rule:message is its own key.
function keyFor(finding, file, fileLines) {
  const m = /^.+?:(\d+):\d+:([^:]+):(.*)$/.exec(finding);
  if (!m) return finding;
  const n = parseInt(m[1], 10);
  const text = n >= 1 && n <= fileLines.length ? fileLines[n - 1].trim() : '';
  return `${file.toLowerCase()}|${m[2]}|${m[3]}|${text}`;
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Skip non-markdown, .claude internals, scratchpad, Temp, node_modules and missing files.
//   3. Find vale; no vale means no check. Lint at warning level and above; nothing exits 0.
//   4. Drop Vale.Spelling findings for words on the Shared accept list.
//   5. Drop findings already shown this session for this file.
//   6. Show up to 15 new findings, remember them, exit 2. Nothing new exits 0.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  const filePath = p.tool_input && p.tool_input.file_path;
  if (!filePath || typeof filePath !== 'string') process.exit(0);
  if (!/\.(md|markdown)$/i.test(filePath)) process.exit(0);
  if (/[\\/]\.claude[\\/]|[\\/]scratchpad[\\/]|[\\/]AppData[\\/]Local[\\/]Temp[\\/]|node_modules/i.test(filePath)) process.exit(0);
  const file = S.resolvePath(filePath, p);
  if (!fs.existsSync(file)) process.exit(0);

  let findings = runVale(findVale(), file);
  if (!findings || findings.length === 0) process.exit(0);

  const accept = loadAccept();
  if (accept) {
    findings = dropAccepted(findings, accept);
    if (findings.length === 0) process.exit(0);
  }

  const seen = new Set();
  const seenFile = seenFileFor(p);
  if (seenFile && fs.existsSync(seenFile)) {
    for (const k of fs.readFileSync(seenFile, 'utf8').split(/\r?\n/)) if (k) seen.add(k);
  }
  const fileLines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  const fresh = [];
  for (const finding of findings) {
    const key = keyFor(finding, file, fileLines);
    if (!seen.has(key)) fresh.push({ line: finding, key });
  }
  if (fresh.length === 0) process.exit(0);

  const shown = fresh.slice(0, SHOW_LIMIT);
  if (seenFile) {
    try {
      fs.mkdirSync(path.dirname(seenFile), { recursive: true });
      fs.appendFileSync(seenFile, shown.map(s => s.key).join('\n') + '\n', 'utf8');
    } catch { }
  }
  const lines = [`Vale (Microsoft style) findings in ${file} - fix them, or silence a rule with a comment in the repo's .vale.ini:`];
  for (const s of shown) lines.push(s.line);
  if (fresh.length > SHOW_LIMIT) lines.push(`(+${fresh.length - SHOW_LIMIT} more - run vale on the file for the full list)`);
  if (findings.length > fresh.length) lines.push(`(${findings.length - fresh.length} more already reported earlier in this session, not repeated)`);
  C.block(lines);
});
