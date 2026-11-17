// =============================================================================
// Script  : pronoun-label-guard.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/pronoun-label-guard.ps1
//                            (created 2026-11-12) for the portable kit. PreToolUse
//                            hook (matcher AskUserQuestion) for the "name who I
//                            and you are" rule. Keith raised it on 2026-08-25,
//                            2026-10-12, 2026-11-11 and 2026-11-12. BLOCKS (exit 2)
//                            a GUI question whose text, header, option labels or
//                            option descriptions hold a bare I, me, my, you or
//                            your, and lists each one so the session can rewrite
//                            it with names. Keith chose the strict level in the
//                            GUI on 2026-11-12. Previews are not checked. Code
//                            spans, fenced code, double-quoted passages and lines
//                            starting with ">" are skipped (see lib/pronoun.js).
//                            Fail-open on any error per reference_hook_semantics.
// Steps:
//   1. Read the PreToolUse payload; fail open on anything unreadable. Step aside when the PowerShell twin exists.
//   2. Pass any tool other than AskUserQuestion.
//   3. Log drift and pass when tool_input.questions is missing.
//   4. Run the shared check on every question; pass when it finds nothing.
//   5. Block (exit 2), listing each field with its bare pronoun and how to fix it.
// =============================================================================
'use strict';
const C = require('./lib/common');
const P = require('./lib/pronoun');

const NAME = 'pronoun-label-guard';

// Steps (main):
//   1. Payload, twin check, AskUserQuestion scope, drift on missing questions.
//   2. Findings from the shared check; none passes.
//   3. Block with one line per finding and the rewrite guidance.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (p.tool_name !== 'AskUserQuestion') process.exit(0);

  const ti = p.tool_input;
  if (!ti || typeof ti !== 'object' || !Object.prototype.hasOwnProperty.call(ti, 'questions')) {
    C.writeDrift(NAME, 'tool_input.questions missing', p);
    process.exit(0);
  }

  const findings = P.getQuestionPronounFindings(ti.questions);
  if (findings.length === 0) process.exit(0);

  const lines = [
    'Pronoun check: this question leaves Keith guessing who "I" or "you" is.',
    'Keith runs many sessions at once, and he reads the question window as his own answer, so a bare pronoun can mean either of you.',
    '',
  ];
  for (const f of findings) lines.push(`  question ${f.question}, ${f.field}: "${f.word}" in "...${f.context}..."`);
  lines.push('');
  lines.push('Rewrite each one with a name ("Claude mints it", "Keith runs one command", "Keith\'s browser"),');
  lines.push('or put a label right after the first one in that field ("I (Claude)", "you (Keith)"), then ask again.');
  lines.push('Labels are short, so a name reads better there than a label. Previews, code in backticks,');
  lines.push('double-quoted text and lines starting with ">" are not checked.');
  C.block(lines);
}

C.run(main);
