// =============================================================================
// Script  : stub-status-copresence.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            stub-status-copresence.ps1 (2026-08-15,
//                            feedback_stub_location_standard, ratified by
//                            Keith 2026-08-15) for the portable kit.
//                            PostToolUse on Write|Edit|MultiEdit for
//                            .ps1/.psm1: reads the SAVED file (full-file
//                            check, so partial edits cannot false-positive)
//                            and enforces the anti-drift invariant: a `# STUB:`
//                            block and a CBH `STATUS: INCOMPLETE` marker
//                            cannot exist without each other. Exit 2 is
//                            feedback to the model (PostToolUse is
//                            non-blocking); fail-open on error. Relative
//                            paths resolve against the project dir.
// =============================================================================
'use strict';
const fs = require('fs');
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'stub-status-copresence';

// Steps (readSaved):
//   1. Resolve the path (relative against the project dir) and return null when the file is missing.
//   2. Return the file text, or null when empty.
function readSaved(filePath, p) {
  const abs = S.resolvePath(filePath, p);
  if (!fs.existsSync(abs)) return null;
  const text = fs.readFileSync(abs, 'utf8');
  return text || null;
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Exit 0 without tool_input, without a .ps1/.psm1 file_path, or when the saved file is missing or empty.
//   3. hasStub = a `# STUB:` marker; hasStatus = a line starting STATUS: INCOMPLETE.
//   4. One without the other exits 2 with the matching message; otherwise exit 0.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (!p.tool_input) process.exit(0);
  const filePath = p.tool_input.file_path;
  if (!filePath || typeof filePath !== 'string' || !/\.(ps1|psm1)$/i.test(filePath)) process.exit(0);

  const text = readSaved(filePath, p);
  if (!text) process.exit(0);

  const hasStub = /#\s*STUB:/i.test(text);
  const hasStatus = /^\s*STATUS:\s*INCOMPLETE/im.test(text);

  if (hasStub && !hasStatus) {
    C.block(`Stub co-presence (stub-location-standard, ratified 2026-08-15): ${filePath} has a '# STUB:' block but no 'STATUS: INCOMPLETE - <what's left>' line in comment-based help .NOTES. Add the help marker so Get-Help users see the gap.`);
  }
  if (hasStatus && !hasStub) {
    C.block(`Stub co-presence (stub-location-standard, ratified 2026-08-15): ${filePath} declares 'STATUS: INCOMPLETE' in help but has no '# STUB:' block at the code site. Add the code-site block (the authored source of truth) or remove the stale help marker.`);
  }
  process.exit(0);
});
