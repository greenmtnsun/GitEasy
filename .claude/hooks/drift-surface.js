// =============================================================================
// Script  : drift-surface.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/drift-surface.ps1
//                            for the portable kit. Stop hook that surfaces any
//                            drift.log entries the other kit hooks wrote during
//                            the session (a payload arrived without the fields
//                            the hook expected for an in-scope tool). After
//                            display the entries are appended to
//                            drift-archive.log and drift.log is cleared so the
//                            next session starts empty. Both files live under the
//                            kit state dir (C.stateDir), never in the repo tree.
//                            Drift should be RARE; recurring drift means the hooks
//                            need updating to match the new payload contract.
// Steps:
//   1. Read the Stop payload; fail open on anything unreadable.
//   2. Read drift.log under the state dir; exit 0 when it is missing or empty.
//   3. Print one stderr line per entry ([Timestamp] Hook: Reason), then archive and clear.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const C = require('./lib/common');

const HOOK = 'drift-surface';

// Steps (readEntries):
//   1. Read the file's non-blank lines; [] when it is missing or unreadable.
function readEntries(file) {
  try {
    return fs.readFileSync(file, 'utf8').split(/\r?\n/).filter(l => l && l.trim().length > 0);
  } catch { return []; }
}

// Steps (describe):
//   1. Parse the entry and format it as "  [Timestamp] Hook: Reason".
//   2. An entry that is not JSON is shown raw, marked unparseable.
function describe(line) {
  try {
    const o = JSON.parse(line);
    return `  [${o.Timestamp}] ${o.Hook}: ${o.Reason}`;
  } catch {
    return `  (unparseable entry: ${line})`;
  }
}

// Steps (main):
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Collect drift.log entries; nothing to do when there are none.
//   3. Write the report to stderr, append the entries to drift-archive.log, clear drift.log; exit 0.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(HOOK)) process.exit(0);

  const dir = C.stateDir(p);
  const driftLog = path.join(dir, 'drift.log');
  const archiveLog = path.join(dir, 'drift-archive.log');

  if (!fs.existsSync(driftLog)) process.exit(0);
  const entries = readEntries(driftLog);
  if (entries.length === 0) process.exit(0);
  const count = entries.length;

  const out = [
    '',
    `=== HOOK CONTRACT DRIFT DETECTED (${count} entries this session) ===`,
    '',
    'Claude Code sent payloads with unexpected shapes during this session.',
    'Expected fields were missing when tool_name said the hook should care.',
    'This may mean the hook contract changed and your hooks need updating.',
    '',
  ];
  for (const line of entries) out.push(describe(line));
  out.push('', `Full entries archived to: ${archiveLog}`, 'drift.log cleared; next session starts empty.', '');
  process.stderr.write(out.join('\n') + '\n');

  try {
    fs.appendFileSync(archiveLog, entries.join('\n') + '\n', 'utf8');
    fs.writeFileSync(driftLog, '', 'utf8');
  } catch { }
  process.exit(0);
}

C.run(main);
