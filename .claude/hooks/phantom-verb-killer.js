// =============================================================================
// Script  : phantom-verb-killer.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            phantom-verb-killer.ps1 (2026-05-07..09) for the
//                            portable kit. PreToolUse on Edit, Write and
//                            MultiEdit to .ps1 files under a Public/ or
//                            Private/ folder inside the project dir. Public/
//                            gets the approved-verb check; Private/ gets the
//                            shape-only check (Verb-Noun: single hyphen,
//                            letters before, alphanumeric after). Malformed
//                            names block in either folder. Node cannot call
//                            Get-Verb, so the list lives in
//                            lib/approved-verbs.js (PowerShell 7.4.6); an
//                            empty list fails open like the original.
//                            Tests\Fixtures exempt; payload drift logged.
// =============================================================================
'use strict';
const C = require('./lib/common');
const S = require('./lib/file-scope');
const APPROVED = require('./lib/approved-verbs');

const NAME = 'phantom-verb-killer';
const IN_SCOPE_TOOLS = ['Edit', 'Write', 'MultiEdit'];
const CONTENT_FIELD = { Edit: 'new_string', Write: 'content', MultiEdit: 'edits' };

// Steps (checkFunctions):
//   1. Capture every `function [scope:]Name` declaration permissively, so malformed names are seen.
//   2. Shape check: single-hyphen Verb-Noun, letters before, alphanumeric after; a miss is a finding.
//   3. For Public/ files only, a verb outside the approved list (case-insensitive, as -notin is) is a finding.
function checkFunctions(content, isPublic, approvedLower) {
  const findings = [];
  for (const m of content.matchAll(/^\s*function\s+(?:global:|script:|local:|private:)?([A-Za-z0-9_-]+)/gim)) {
    const fname = m[1];
    const shape = /^([A-Za-z]+)-([A-Za-z0-9]+)$/.exec(fname);
    if (!shape) { findings.push(`Malformed function name: '${fname}' (expected Verb-Noun shape)`); continue; }
    if (isPublic && !approvedLower.has(shape[1].toLowerCase())) findings.push(`Unapproved verb: ${fname}`);
  }
  return findings;
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Only Edit, Write and MultiEdit matter. Log drift and exit 0 when tool_input or file_path is missing.
//   3. Exit 0 outside the project dir, outside a Public/ or Private/ folder, for non-.ps1 files, or under Tests\Fixtures.
//   4. Log drift and exit 0 when the content field is missing; exit 0 on empty content or an empty verb list.
//   5. Check each function declaration; no findings exits 0, else block with the folder-specific guidance.
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
  const isPublic = S.hasFolder(scope, 'Public');
  const isPrivate = S.hasFolder(scope, 'Private');
  if (!(isPublic || isPrivate)) process.exit(0);
  if (!/\.ps1$/i.test(filePath)) process.exit(0);
  if (S.isTestFixture(scope)) process.exit(0);

  const content = C.editedText(p);
  if (content === null) { C.writeDrift(NAME, `tool_input.${CONTENT_FIELD[tool]} missing`, p); process.exit(0); }
  if (!content) process.exit(0);
  if (!Array.isArray(APPROVED) || APPROVED.length === 0) process.exit(0);

  const findings = checkFunctions(content, isPublic, new Set(APPROVED.map(v => v.toLowerCase())));
  if (findings.length === 0) process.exit(0);

  C.block([
    `Phantom-verb killer: blocked save to ${filePath}`,
    '',
    ...findings.map(f => `  ${f}`),
    '',
    isPublic
      ? 'Public-surface commands must use approved verbs. Run Get-Verb to list them.'
      : 'Private functions must use Verb-Noun shape (single hyphen, letters before, alphanumeric after).',
    '(Per ModuleWorkshop DR-005.)',
  ]);
});
