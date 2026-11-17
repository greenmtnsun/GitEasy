// =============================================================================
// Script  : gui-decision-guard.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            hooks/gui-decision-guard.ps1 for the portable kit.
//                            Stop hook for the "ask in the GUI, never inline"
//                            rule (feedback_autonomy_and_gui_questions +
//                            feedback_decision_prompts). Blocks (exit 2) when the
//                            final reply waits on Keith outside AskUserQuestion:
//                            an offer-phrased question, a wait phrase ("waiting
//                            on your call", "say the word", "tell me which",
//                            "still need you") or a reply ending on a question.
//                            Passes when the turn called AskUserQuestion, when the
//                            reply carries <!-- inline-ok -->, or after blocking
//                            twice in one turn (each such pass is recorded in
//                            gui-guard-cap.log under the kit state dir, or the
//                            file GUI_GUARD_CAP_LOG names). The check itself lives
//                            in lib/transcript.js. Fail-open on anything unexpected.
// Steps:
//   1. Read the Stop payload; fail open on anything unreadable or without a transcript.
//   2. Take the final reply from last_assistant_message. If it is missing, log drift
//      and use the transcript's last reply instead.
//   3. Read the end of the transcript for the current turn; pass if it called
//      AskUserQuestion, or if this guard already blocked twice in it (recorded in
//      gui-guard-cap.log).
//   4. Pass an empty reply, or one marked <!-- inline-ok -->.
//   5. Block (exit 2) when a line of the reply waits on Keith, quoting that line.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const C = require('./lib/common');
const T = require('./lib/transcript');

const HOOK = 'gui-decision-guard';

// Steps (capLogPath):
//   1. GUI_GUARD_CAP_LOG when set (tests point it at a scratch file).
//   2. Else gui-guard-cap.log under the kit state dir.
function capLogPath(payload) {
  return process.env.GUI_GUARD_CAP_LOG || path.join(C.stateDir(payload), 'gui-guard-cap.log');
}

// Steps (main):
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Resolve the final reply and the current turn from the transcript tail.
//   3. Pass on a GUI question this turn, on the two-block cap (logged), on an empty reply
//      or an inline-ok marker; otherwise block, quoting the waiting line.
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

  let lastText = null;
  if (Object.prototype.hasOwnProperty.call(p, 'last_assistant_message')) {
    lastText = p.last_assistant_message == null ? '' : String(p.last_assistant_message);
  } else {
    C.writeDrift(HOOK, 'last_assistant_message missing; read the transcript instead', p);
  }

  let turn;
  try { turn = T.getCurrentTurn(transcript); } catch { process.exit(0); }

  // Something was asked in the GUI this turn; nothing to enforce.
  if (turn.askUsed) process.exit(0);

  // Two blocks in one turn is enough; a third would only loop the session. Each pass is
  // recorded so an audit can count the replies that got through.
  if (turn.guardBlocks >= 2) {
    C.appendJsonLine(capLogPath(p), {
      Timestamp: new Date().toISOString(),
      Session: p.session_id,
      Transcript: transcript,
    });
    process.exit(0);
  }

  if (lastText === null) lastText = turn.lastText;
  if (!lastText) process.exit(0);

  // Deliberate inline question, explicitly marked.
  if (/<!--\s*inline-ok\s*-->/i.test(lastText)) process.exit(0);

  const line = T.getInlineAskLine(lastText);
  if (!line) process.exit(0);

  C.block([
    'GUI-decision guard: your reply waits on Keith outside the GUI. This line does it:',
    '',
    '    ' + line,
    '',
    'Anything you need from Keith goes in AskUserQuestion, in this same turn: a decision,',
    'an approval, "should I continue", or a step he has to do by hand (offer options such',
    'as "Done" and "Not yet"). Use plain words and put the recommended option first. When',
    'an option changes something he can picture, give it a preview: a short before/after',
    'text picture of what changes (single-choice questions only). He answers the GUI; he',
    'misses questions in text.',
    '',
    'If nothing is actually waiting on Keith, reword that line so it does not read as a',
    'wait. For a rare, deliberate inline question, add <!-- inline-ok --> and it passes.',
  ]);
}

C.run(main);
