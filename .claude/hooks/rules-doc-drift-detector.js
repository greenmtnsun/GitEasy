// =============================================================================
// Script  : rules-doc-drift-detector.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            rules-doc-drift-detector.ps1 (2026-05-08) for the
//                            portable kit. PostToolUse on Edit|Write|MultiEdit.
//                            Detects edits to skill files (skills/*/SKILL.md),
//                            hook scripts (hooks/*.ps1 and kit/hooks/*.js) and
//                            feedback memories (projects/*/memory/
//                            feedback_*.md) inside the project dir. On match,
//                            appends one line to rules-doc-drift.log under the
//                            kit state dir so Keith (or a future session)
//                            knows SKILLS_AND_RULES_PLAIN_ENGLISH.md has stale
//                            sections. Always exits 0: an observer, never a
//                            blocker.
// =============================================================================
'use strict';
const path = require('path');
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'rules-doc-drift-detector';
const IN_SCOPE_TOOLS = ['Edit', 'Write', 'MultiEdit'];

// Steps (categorise):
//   1. Read the relative path's segments from the end, ignoring case.
//   2. skills/<name>/SKILL.md -> skill; hooks/<x>.ps1 or kit/hooks/<x>.js -> hook; projects/<name>/memory/feedback_*.md -> feedback.
//   3. Anything else -> null.
function categorise(scope) {
  const seg = scope.segments.map(s => s.toLowerCase());
  const n = seg.length;
  const file = seg[n - 1] || '';
  const d1 = seg[n - 2] || '';
  const d2 = seg[n - 3] || '';
  const d3 = seg[n - 4] || '';
  if (file === 'skill.md' && d2 === 'skills' && d1) return 'skill';
  if (d1 === 'hooks' && /\.ps1$/.test(file)) return 'hook';
  if (d1 === 'hooks' && d2 === 'kit' && /\.js$/.test(file)) return 'hook';
  if (d1 === 'memory' && d3 === 'projects' && d2 && /^feedback_.*\.md$/.test(file)) return 'feedback';
  return null;
}

// Steps (localStamp):
//   1. Format the current local time as yyyy-MM-ddTHH:mm:ss with the UTC offset (+HH:mm), matching Get-Date 'yyyy-MM-ddTHH:mm:ssK'.
function localStamp() {
  const d = new Date();
  const pad = n => String(n).padStart(2, '0');
  const off = -d.getTimezoneOffset();
  const sign = off >= 0 ? '+' : '-';
  const abs = Math.abs(off);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}${sign}${pad(Math.floor(abs / 60))}:${pad(abs % 60)}`;
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Only Edit, Write and MultiEdit matter; exit 0 without tool_input or file_path, or outside the project dir.
//   3. Categorise the path; no category exits 0.
//   4. Append "<stamp> | <category> | <tool> | <path>" to rules-doc-drift.log in the state dir; always exit 0.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  const tool = p.tool_name;
  if (!IN_SCOPE_TOOLS.includes(tool)) process.exit(0);
  if (!p.tool_input || !Object.prototype.hasOwnProperty.call(p.tool_input, 'file_path')) process.exit(0);
  const filePath = p.tool_input.file_path;
  if (!filePath) process.exit(0);

  const scope = S.inProject(filePath, p);
  if (!scope) process.exit(0);
  const category = categorise(scope);
  if (!category) process.exit(0);

  const logPath = path.join(C.stateDir(p), 'rules-doc-drift.log');
  try { require('fs').appendFileSync(logPath, `${localStamp()} | ${category} | ${tool} | ${filePath}\n`, 'utf8'); } catch { }
  process.exit(0);
});
