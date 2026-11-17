// =============================================================================
// Script  : context-warn.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/context-warn.ps1
//                            for the portable kit. UserPromptSubmit hook: emits a
//                            visible marker when the session context exceeds
//                            150k tokens, read from the most recent API usage
//                            record at the end of the transcript. Under the
//                            threshold it is silent. Adds one thing the original
//                            lacked: a missing transcript_path is logged as
//                            drift (exit code unchanged). Never blocks the prompt.
// Steps:
//   1. Read the hook payload from stdin; take transcript_path.
//   2. Tail the last 128 KB of the transcript (the live session holds it open).
//   3. Scan lines backwards for the most recent API usage record.
//   4. Compute context = input_tokens + cache_creation_input_tokens + cache_read_input_tokens.
//   5. Under 150k: exit 0 silently. Over 150k: emit JSON with systemMessage (Keith's marker)
//      and additionalContext (nudges Claude to recommend /compact or /clear).
//   6. Fail open: any error exits 0 with no output.
// =============================================================================
'use strict';
const fs = require('fs');
const C = require('./lib/common');

const HOOK = 'context-warn';
const TAIL_BYTES = 131072;
const THRESHOLD = 150000;

// Steps (latestContext):
//   1. Walk the tail's lines from the end to the first one holding cache_read_input_tokens.
//   2. Sum input, cache-creation and cache-read tokens from that line; -1 when none is found.
function latestContext(tail) {
  const lines = tail.split('\n');
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (!line.includes('"cache_read_input_tokens"')) continue;
    const num = re => { const m = re.exec(line); return m ? Number(m[1]) : 0; };
    return num(/"input_tokens":(\d+)/) + num(/"cache_creation_input_tokens":(\d+)/) + num(/"cache_read_input_tokens":(\d+)/);
  }
  return -1;
}

// Steps (main):
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Log drift and pass when transcript_path is missing; pass when the file is absent.
//   3. Compute the latest context size from the transcript tail; emit the marker over 150k.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(HOOK)) process.exit(0);

  if (!Object.prototype.hasOwnProperty.call(p, 'transcript_path')) {
    C.writeDrift(HOOK, 'transcript_path missing', p);
    process.exit(0);
  }
  const tp = p.transcript_path;
  if (typeof tp !== 'string' || !tp || !fs.existsSync(tp)) process.exit(0);

  const tail = C.readTail(tp, TAIL_BYTES);
  if (!tail) process.exit(0);

  const ctx = latestContext(tail);
  if (ctx <= THRESHOLD) process.exit(0);

  const k = Math.round(ctx / 1000);
  const msg = `-- context ${k}k >150k as part of context-hygiene -- /compact (mid-task) or /clear (task boundary) recommended`;
  C.emit({
    systemMessage: msg,
    hookSpecificOutput: { hookEventName: 'UserPromptSubmit', additionalContext: msg },
  });
  process.exit(0);
}

C.run(main);
