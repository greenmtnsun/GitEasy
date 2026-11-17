// =============================================================================
// Script  : ps-authoring-guards.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            ps-authoring-guards.ps1 (2026-08-15) for the
//                            portable kit. One PreToolUse guard for
//                            Edit|Write|MultiEdit payloads to .ps1/.psm1, two
//                            checks: (1) CBH dot-leading lines: inside a
//                            <# ... #> block, a line starting `.Word` that is
//                            not a CBH keyword kills the whole help at
//                            Get-Help time (feedback_cbh_no_dot_leading_lines);
//                            (2) Pester It names with a tag-like <placeholder>
//                            break discovery (feedback_pester_test_names_no_
//                            angle_brackets), *.Tests.ps1 only. Like the
//                            original this has no folder scope: it runs on
//                            any .ps1/.psm1 path. Cheap-first; fail-open.
//                            Note: the original printed each offending word
//                            from a regex group that does not exist, so its
//                            message read "starting with ." - this port
//                            names the words, which the message intends.
// =============================================================================
'use strict';
const C = require('./lib/common');

const NAME = 'ps-authoring-guards';
const CBH_KEYWORDS = 'SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|NOTES|LINK|INPUTS|OUTPUTS|COMPONENT|ROLE|FUNCTIONALITY|EXTERNALHELP|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|DYNAMICPARAMETER';

// Steps (editedText):
//   1. MultiEdit: the joined new_strings from common.editedText.
//   2. Otherwise join whichever of content and new_string are present, as the original does.
function editedText(p) {
  if (p.tool_name === 'MultiEdit') return C.editedText(p) || '';
  return [p.tool_input.content, p.tool_input.new_string].filter(s => typeof s === 'string').join('\n');
}

// Steps (findBadDotLines):
//   1. Skip the regex work when the text has no <# at all.
//   2. For each <# ... #> span (an unterminated span runs to the end of the text), collect lines starting .Word where Word is not a CBH keyword.
//   3. Return the distinct offending words, dot-prefixed, in order of first appearance.
function findBadDotLines(text) {
  if (!text.includes('<#')) return [];
  const badRx = new RegExp(`^\\s*\\.(?!(?:${CBH_KEYWORDS})\\b)([A-Za-z][\\w-]*)`, 'gim');
  const names = [];
  for (const span of text.matchAll(/<#[\s\S]*?(?:#>|$(?![\s\S]))/g)) {
    for (const m of span[0].matchAll(badRx)) {
      const n = '.' + m[1];
      if (!names.includes(n)) names.push(n);
    }
  }
  return names;
}

// Steps (hasAngleBracketItName):
//   1. Only *.Tests.ps1 files are checked.
//   2. True when an It name's quoted string contains < followed by a letter or slash (a tag-like placeholder).
function hasAngleBracketItName(filePath, text) {
  if (!/\.Tests\.ps1$/i.test(filePath)) return false;
  return /\bIt\s+(['"])[^'"]*<[a-z/]/i.test(text);
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Exit 0 without tool_input, without a .ps1/.psm1 file_path, or with no edited text.
//   3. CBH check first: any bad dot-leading line blocks with the backtick-quote fix.
//   4. Pester check second: an It name with a tag-like <placeholder> blocks in *.Tests.ps1.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (!p.tool_input) process.exit(0);
  const filePath = p.tool_input.file_path;
  if (!filePath || typeof filePath !== 'string' || !/\.(ps1|psm1)$/i.test(filePath)) process.exit(0);

  const text = editedText(p);
  if (!text) process.exit(0);

  const bad = findBadDotLines(text);
  if (bad.length > 0) {
    C.block([
      `CBH guard: BLOCKED - line(s) starting with ${bad.join(', ')} inside a <# #> help block.`,
      'A body line starting with `.Word` that is not a CBH keyword silently kills the',
      'ENTIRE comment-based help (feedback_cbh_no_dot_leading_lines). Backtick-quote the',
      'keyword reference (e.g. `.EXAMPLE`) or reword so the line does not start with a dot.',
    ]);
  }

  if (hasAngleBracketItName(filePath, text)) {
    C.block([
      'Pester guard: BLOCKED - It name contains a tag-like <placeholder>.',
      'Angle-bracket placeholders in It names break discovery/reporting',
      '(feedback_pester_test_names_no_angle_brackets). Use plain words instead.',
    ]);
  }
  process.exit(0);
});
