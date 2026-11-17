// =============================================================================
// Script  : sub-agent-honesty-injection.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/sub-agent-honesty-injection.ps1
//                            (created 2026-05-13, ship-scope check G6b added
//                            2026-08-15) for the portable kit. PreToolUse hook on
//                            the Agent tool. Blocks any Agent invocation whose
//                            prompt does not contain the keyword "fabricate",
//                            taken as a proxy for the feedback_no_stealth_completion
//                            honesty preamble (its central clause is "do not
//                            fabricate paths, APIs, results, or capabilities").
//                            Sub-agents don't read parent memories, so the
//                            mechanical guarantee is at the prompt boundary.
//                            Stderr on block includes the exact preamble to paste.
//                            A prompt that says deploy, publish or ship without
//                            naming PIPELINE is blocked first: an agent told to
//                            ship without the ledger is how phases get skipped
//                            out of sight ("release" is excluded; it fires on
//                            release notes and file locks). Fail-open on any error
//                            per reference_hook_semantics.
// Steps:
//   1. Read the payload; fail open on anything unreadable. Step aside when the PowerShell twin exists.
//   2. Pass any tool other than Agent. Log drift and pass when tool_input or tool_input.prompt is missing.
//   3. An empty prompt passes.
//   4. deploy|publish|ship in the prompt without PIPELINE blocks with the ledger message.
//   5. The word fabricate anywhere passes; otherwise block with the preamble to paste.
// =============================================================================
'use strict';
const C = require('./lib/common');

const NAME = 'sub-agent-honesty-injection';

// Steps (main):
//   1. Payload, twin check, Agent scope, drift on a missing prompt.
//   2. Ship-scope check, then the fabricate keyword check; block with the matching stderr text.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (p.tool_name !== 'Agent') process.exit(0);

  const ti = p.tool_input;
  if (!ti || typeof ti !== 'object') { C.writeDrift(NAME, 'tool_input missing', p); process.exit(0); }
  if (!Object.prototype.hasOwnProperty.call(ti, 'prompt')) { C.writeDrift(NAME, 'tool_input.prompt missing', p); process.exit(0); }

  const prompt = ti.prompt == null ? '' : String(ti.prompt);
  if (!prompt) process.exit(0);

  if (/\b(deploy|publish|ship)\b/i.test(prompt) && !/PIPELINE/i.test(prompt)) {
    C.block([
      'Sub-agent honesty hook: ship-scoped Agent prompt without ledger awareness.',
      'The prompt says deploy/publish/ship but never mentions PIPELINE. Tell the agent',
      'which Docs\\PIPELINE.md governs this work and that phase statuses must be recorded',
      'there (official delivery process). Then relaunch.',
    ]);
  }

  if (/fabricate/i.test(prompt)) process.exit(0);

  C.block([
    'Sub-agent honesty hook: Agent prompt is missing the no-fabrication preamble.',
    '',
    'Sub-agents do not read parent memories, so the honesty rule',
    '(feedback_no_stealth_completion) has to ride in the prompt itself.',
    '',
    'Add this preamble to the top of the prompt (or anywhere in it — the hook',
    'looks for the keyword "fabricate" as proof the preamble is present):',
    '',
    '---',
    'Honesty rule: do not fabricate paths, APIs, results, or capabilities.',
    'Do not weaken assertions to pass checks. Inspection is not verification —',
    'cite the test ID, command + exit code, or file read that produced any',
    '"verified / tested / works" claim. If validation fails after one fix',
    'attempt, stop and report. State what was not verified.',
    '---',
  ]);
}

C.run(main);
