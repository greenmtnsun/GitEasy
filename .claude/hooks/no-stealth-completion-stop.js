// =============================================================================
// Script  : no-stealth-completion-stop.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            hooks/no-stealth-completion-stop.ps1 for the
//                            portable kit. Stop hook for the
//                            feedback_no_stealth_completion rule: a reply that
//                            carries a completion-claim word (done | completed |
//                            finished | shipped | landed | implemented | fixed |
//                            merged | committed | ready to ship | ready for
//                            prod/release/launch | good to go) must carry a
//                            <!-- verified --> or <!-- not-verified --> marker
//                            (legacy <verified> / <not-verified> tags still
//                            pass). "fixed" as an adjective (a/an/no/any/some/
//                            one fixed, fixed-width) is not a claim. The final
//                            reply comes from last_assistant_message; the
//                            transcript's end is the fallback, logged as drift.
//                            Fail-open on anything unexpected.
// Steps:
//   1. Read the Stop payload; fail open on anything unreadable or without a transcript.
//   2. Take the final reply from last_assistant_message. If it is missing, log drift
//      and use the last reply in the transcript's current turn instead.
//   3. Pass a reply with no completion word, or one carrying a verified or
//      not-verified marker.
//   4. Otherwise block (exit 2) with the closeout shape.
// =============================================================================
'use strict';
const fs = require('fs');
const C = require('./lib/common');
const T = require('./lib/transcript');

const HOOK = 'no-stealth-completion-stop';

// Completion-claim trigger words. Word-boundary anchored; case-insensitive.
// "ready" and bare "complete" excluded: too common in conversational use
// ("ready when you are," "complete data set"). Compound "ready" phrases count.
// "fixed" is skipped where it is an adjective, not a claim: after
// a/an/no/any/some/one ("no fixed check", "a fixed price") or before a hyphen
// ("fixed-width"). "I fixed X" and "X is fixed" still fire.
const claimPattern = /\b(done|completed|finished|shipped|landed|implemented|(?<!\b(a|an|no|any|some|one)\s+)fixed(?!-)|merged|committed|ready to ship|ready for (prod(uction)?|release|launch)|good to go)\b/i;

// Steps (main):
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Resolve the final reply (payload field first, transcript tail second).
//   3. Pass when no claim word, or a marker of either style, is present; else block.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(HOOK)) process.exit(0);

  if (!Object.prototype.hasOwnProperty.call(p, 'transcript_path')) {
    C.writeDrift(HOOK, 'transcript_path missing', p);
    process.exit(0);
  }
  const transcript = p.transcript_path;
  if (typeof transcript !== 'string' || !fs.existsSync(transcript)) {
    C.writeDrift(HOOK, 'transcript file not found', p);
    process.exit(0);
  }

  // The final reply comes with the payload; the transcript may not hold it yet.
  let lastText = null;
  if (Object.prototype.hasOwnProperty.call(p, 'last_assistant_message')) {
    lastText = p.last_assistant_message == null ? '' : String(p.last_assistant_message);
  } else {
    C.writeDrift(HOOK, 'last_assistant_message missing; read the transcript end instead', p);
    try { lastText = T.getCurrentTurn(transcript).lastText; } catch { process.exit(0); }
  }

  // No assistant text means there is nothing to enforce against (e.g. tool-only turn).
  if (!lastText) process.exit(0);
  if (!claimPattern.test(lastText)) process.exit(0);

  // Either marker style: the HTML comment (preferred, invisible in rendered Markdown)
  // or the legacy <verified>...</verified> tags from before the format change.
  const hasVerified = /<!--\s*verified\s*-->/i.test(lastText) || /<verified>/i.test(lastText);
  const hasNotVerified = /<!--\s*not-verified\s*-->/i.test(lastText) || /<not-verified>/i.test(lastText);
  if (hasVerified || hasNotVerified) process.exit(0);

  C.block([
    'No-stealth-completion hook: completion claim without verification markers.',
    '',
    'Your last assistant turn contained a completion word',
    '(done / completed / finished / shipped / landed / implemented / fixed /',
    'merged / committed) but did not include either a <!-- verified --> or',
    '<!-- not-verified --> marker.',
    '',
    'Per feedback_no_stealth_completion, completion-claiming turns must end with',
    'a visible closeout PLUS invisible HTML-comment markers. Standard shape:',
    '',
    '  <!-- verified -->',
    '  > **Verified**',
    '  > - One full English sentence per item: say WHAT you proved and HOW,',
    '  >   readable by someone who was not watching the session. Example:',
    '  >   "The module now loads in both PowerShell editions - I imported it',
    '  >   in each and both reported version 2.9.0." Put the raw command,',
    '  >   test ID, or file:line AFTER the sentence if useful - never INSTEAD',
    '  >   of it.',
    '',
    '  <!-- not-verified -->',
    '  > **Not verified**',
    '  > - One full English sentence: what remains unproven, why it could not',
    '  >   be checked from here, and what would prove it.',
    '',
    'Keith reads these closeouts. Bare artifact IDs, exit codes, or file:line',
    'references with no sentence around them are not a closeout - they are the',
    '"speaking in tongues" he has rejected. Plain sentences first, evidence after.',
  ]);
}

C.run(main);
