// =============================================================================
// Script  : no-here-string-guard.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            no-here-string-guard.ps1 (2026-05-07/08) for the
//                            portable kit. PreToolUse on Edit, Write and
//                            MultiEdit to .ps1/.psm1 inside the project dir:
//                            blocks saves that introduce a here-string opener
//                            (@" or @' at end of line) and suggests the
//                            line-array pattern. Carve-outs kept, as path
//                            segments: Private/New-*Text.ps1 (Option A text
//                            builders) and SqlBackupValidation/Private/
//                            Invoke-Sbv*.ps1 (DR-013). Tests\Fixtures exempt.
//                            Payload-shape drift is logged; the hook exits 0.
// =============================================================================
'use strict';
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'no-here-string-guard';
const IN_SCOPE_TOOLS = ['Edit', 'Write', 'MultiEdit'];
const CONTENT_FIELD = { Edit: 'new_string', Write: 'content', MultiEdit: 'edits' };

// Steps (isCarveOut):
//   1. Private/New-<Upper>*Text.ps1: sanctioned text-builder helpers may use here-strings.
//   2. SqlBackupValidation/Private/Invoke-Sbv*.ps1: single-quoted T-SQL templates (DR-013, 2026-05-31).
function isCarveOut(scope) {
  const seg = scope.segments;
  const n = seg.length;
  const name = seg[n - 1] || '';
  const parent = (seg[n - 2] || '').toLowerCase();
  const grand = (seg[n - 3] || '').toLowerCase();
  if (parent === 'private' && /^New-[A-Z]\w*Text\.ps1$/i.test(name)) return true;
  if (grand === 'sqlbackupvalidation' && parent === 'private' && /^Invoke-Sbv[A-Za-z]+\.ps1$/i.test(name)) return true;
  return false;
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Only Edit, Write and MultiEdit matter. Log drift and exit 0 when tool_input or file_path is missing.
//   3. Exit 0 outside the project dir, for non-.ps1/.psm1 files, under Tests\Fixtures, or for a carve-out file.
//   4. Log drift and exit 0 when the content field is missing; exit 0 on empty content.
//   5. Count here-string openers (@" or @' at end of line); none exits 0, else block with the line-array suggestion.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  const tool = p.tool_name;
  if (!IN_SCOPE_TOOLS.includes(tool)) process.exit(0);
  if (!p.tool_input) { C.writeDrift(NAME, 'tool_input missing', p); process.exit(0); }
  if (!Object.prototype.hasOwnProperty.call(p.tool_input, 'file_path')) { C.writeDrift(NAME, 'tool_input.file_path missing', p); process.exit(0); }
  const filePath = p.tool_input.file_path;
  if (!filePath) process.exit(0);

  const scope = S.inProject(filePath, p);
  if (!scope) process.exit(0);
  if (!/\.(ps1|psm1)$/i.test(filePath)) process.exit(0);
  if (S.isTestFixture(scope)) process.exit(0);
  if (isCarveOut(scope)) process.exit(0);

  const content = C.editedText(p);
  if (content === null) { C.writeDrift(NAME, `tool_input.${CONTENT_FIELD[tool]} missing`, p); process.exit(0); }
  if (!content) process.exit(0);

  const openings = content.match(/@["'][ \t]*\r?$/gm) || [];
  if (openings.length === 0) process.exit(0);

  C.block([
    `No-here-string guard: blocked save to ${filePath}`,
    '',
    `Found ${openings.length} here-string opener(s). Use the line-array pattern instead:`,
    '',
    '  $sql = @(',
    '    "SELECT name"',
    '    "FROM sys.databases"',
    '  ) -join "`r`n"',
  ]);
});
