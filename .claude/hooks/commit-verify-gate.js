// =============================================================================
// Script  : commit-verify-gate.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/commit-verify-gate.ps1
//                            for the portable kit. PreToolUse hook for Bash and
//                            PowerShell commands that commit (git commit, or
//                            GitEasy's Save-Work) and for the GitEasy
//                            mcp__giteasy__save_work tool. Looks for a `Verified:`
//                            trailer in the commit message, the commit-level form
//                            of honest-completion's citation rule. Three modes,
//                            read from env COMMIT_VERIFY_GATE_MODE, else the first
//                            non-comment line of commit-verify-gate.mode beside
//                            this file, else observe:
//                              off      - nothing happens.
//                              observe  - no trailer passes, is logged as
//                                         would-block, and Claude is told.
//                              enforce  - no trailer blocks (exit 2). After two
//                                         blocks in one session the third commit
//                                         passes and is logged, so a session
//                                         never wedges.
//                            `Verified: none` passes only with a reason after it.
//                            Every decision is one JSON line in
//                            commit-verify-gate.log under the kit state dir (env
//                            COMMIT_VERIFY_GATE_LOG overrides). A commit is found
//                            on a skeleton of the command, with heredoc bodies,
//                            quoted strings and comments taken out, so
//                            `rg 'git commit' hooks/` is not a commit. The trailer
//                            is read only from the message itself: the -m,
//                            --message and -Message arguments (a heredoc inside
//                            one resolves to its body), or the -F file. For the
//                            GitEasy tool, a field whose name contains message,
//                            msg or commit is the message; with none, every string
//                            field is read and drift is logged. A commit with no
//                            message argument (an editor commit) passes untouched.
//                            Fail-open on any error per reference_hook_semantics.
// Steps:
//   1. Read the payload; fail open on anything unreadable. Step aside when the
//      PowerShell twin exists on the PC.
//   2. Work out the mode: the env override, else the first non-comment line of
//      commit-verify-gate.mode, else observe. An unknown mode logs drift and
//      means observe. off exits 0.
//   3. Find the commit. Bash or PowerShell: build the skeleton (heredoc bodies,
//      quoted strings and comments replaced by tokens) and look for git commit or
//      Save-Work in it. Anything else exits 0. An amend with no message argument
//      exits 0.
//   4. Collect the message text: each -m, --message or -Message argument,
//      resolved back to its quoted text or heredoc body, plus the -F or --file (-F - takes the heredoc body)
//      contents when the file exists. No message argument at all exits 0. For
//      mcp__giteasy__save_work, the message-named field, else every string field.
//   5. Take the Verified: trailer from the message text. none counts only when
//      a reason follows it.
//   6. A usable trailer passes and is logged as pass.
//   7. No trailer: observe logs would-block and tells Claude on stdout; enforce
//      blocks with exit 2, unless this session already has two blocked entries
//      in the log, when it passes with a note and is logged as
//      pass-after-two-blocks.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const C = require('./lib/common');

const NAME = 'commit-verify-gate';

// Steps (getCommandSkeleton):
//   1. Replace each heredoc (<<'TAG' or <<TAG through its closing TAG line) with a token and keep its body.
//   2. Replace each double-quoted string (backslash and backtick escapes honoured) with a token and keep its contents.
//   3. Replace each single-quoted string (a doubled quote stays inside) with a token and keep its contents.
//   4. Remove comments: a # at the start of a line or after whitespace, to the end of the line.
//   5. Return the skeleton, the token-to-text table, and the heredoc tokens' keys in order. A quoted text may itself hold a heredoc token.
function getCommandSkeleton(command) {
  let n = 0;
  const table = {};
  const heredocKeys = [];
  const tok = (text) => { n++; const k = `__TOK${n}__`; table[k] = text; return k; };
  let text = command.replace(/<<-?\s*(["']?)([A-Za-z_]\w*)\1[^\r\n]*\r?\n([\s\S]*?)\r?\n[ \t]*\2(?=[\s);]|$)/g, (m, q, tag, body) => { const k = tok(body); heredocKeys.push(k); return k; });
  text = text.replace(/"((?:[^"\\`]|\\.|`.)*)"/g, (m, s) => tok(s));
  text = text.replace(/'((?:[^']|'')*)'/g, (m, s) => tok(s.replace(/''/g, "'")));
  text = text.replace(/(^|\s)#[^\r\n]*/gm, '$1');
  return { skeleton: text, table, heredocKeys };
}

// Steps (resolveSkeletonToken):
//   1. Replace every __TOKn__ in the argument with its stored text, repeating while tokens remain (a quoted string can hold a heredoc token).
//   2. Stop after eight rounds, so a pathological input cannot loop.
//   3. Return the text.
function resolveSkeletonToken(value, table) {
  let out = value;
  for (let i = 0; i < 8 && /__TOK\d+__/.test(out); i++) {
    out = out.replace(/__TOK\d+__/g, (m) => Object.prototype.hasOwnProperty.call(table, m) ? table[m] : '');
  }
  return out;
}

// Steps (addGateLog):
//   1. Build the entry: timestamp, mode, outcome, session, cwd, what was committed with, the trailer, and the first 200 characters of the command.
//   2. Append it to the gate log as one compact JSON line, UTF-8 without BOM.
//   3. Swallow any write failure: logging never changes the gate's answer.
function addGateLog(logPath, mode, outcome, session, cwd, what, trailer, command) {
  let snippet = command ? command.replace(/\s+/g, ' ').trim() : '';
  if (snippet.length > 200) snippet = snippet.slice(0, 200) + '...';
  C.appendJsonLine(logPath, {
    Timestamp: new Date().toISOString(), Mode: mode, Outcome: outcome, Session: session, Cwd: cwd,
    What: what, Trailer: trailer || null, Command: snippet,
  });
}

// Steps (getSessionBlockCount):
//   1. Return 0 when the log does not exist.
//   2. Read each line; skip lines that do not name this session, so a long log stays cheap.
//   3. Parse the rest as JSON and count those with Outcome blocked and the same Session.
//   4. Return the count. Any read or parse failure counts as 0, which keeps the gate strict.
function getSessionBlockCount(logPath, session) {
  try {
    if (!fs.existsSync(logPath)) return 0;
    let count = 0;
    for (const line of fs.readFileSync(logPath, 'utf8').split(/\r?\n/)) {
      if (line.indexOf(session) < 0) continue;
      let e;
      try { e = JSON.parse(line); } catch { continue; }
      if (e && e.Session === session && e.Outcome === 'blocked') count++;
    }
    return count;
  } catch { return 0; }
}

// Steps (readMode):
//   1. Env COMMIT_VERIFY_GATE_MODE wins when set.
//   2. Else the mode file: env COMMIT_VERIFY_GATE_MODE_FILE, else commit-verify-gate.mode beside this script; its first line that is not blank or a comment.
//   3. Else observe. Lower-case and trim; an unknown value logs drift and means observe.
function readMode(payload) {
  let mode = 'observe';
  if (process.env.COMMIT_VERIFY_GATE_MODE) {
    mode = process.env.COMMIT_VERIFY_GATE_MODE;
  } else {
    const modePath = process.env.COMMIT_VERIFY_GATE_MODE_FILE || path.join(__dirname, 'commit-verify-gate.mode');
    try {
      if (fs.existsSync(modePath)) {
        const first = fs.readFileSync(modePath, 'utf8').split(/\r?\n/).map(l => l.trim()).find(l => l && !/^#/.test(l));
        if (first) mode = first;
      }
    } catch { }
  }
  mode = String(mode).trim().toLowerCase();
  if (!['off', 'observe', 'enforce'].includes(mode)) {
    C.writeDrift(NAME, `unknown mode '${mode}'; using observe`, payload);
    mode = 'observe';
  }
  return mode;
}

// Steps (collectShellMessage):
//   1. Build the skeleton; look for git commit or Save-Work in it. Return null when neither is there.
//   2. Resolve each -m / --message (git) or -Message (Save-Work) argument back to its text.
//   3. For git, add the -F / --file contents when the file exists, else an empty part.
//   4. No message argument at all returns null (an editor commit); else the parts joined with newlines, plus what was committed with.
function collectShellMessage(command) {
  const sk = getCommandSkeleton(command);
  const skeleton = sk.skeleton;
  const isGitCommit = /(^|[\s;&|(])git(\.exe)?(\s+-[A-Za-z]\s+\S+|\s+--?[A-Za-z][\w-]*(=\S+)?)*\s+commit(?![-\w])/i.test(skeleton);
  const isSaveWork = /(^|[\s;&|{(])Save-Work(?![-\w])/i.test(skeleton);
  if (!(isGitCommit || isSaveWork)) return null;
  const what = isGitCommit ? 'git commit' : 'Save-Work';

  const parts = [];
  const argPattern = isGitCommit ? /(?<!\S)(?:-[A-Za-z]*m|--message)(?:=|\s+)(\S+)/g : /(?<!\S)-Message(?::|\s+)(\S+)/gi;
  for (const m of skeleton.matchAll(argPattern)) parts.push(resolveSkeletonToken(m[1], sk.table));
  if (isGitCommit) {
    const fm = skeleton.match(/(?<!\S)(?:-F|--file)(?:=|\s+)(\S+)/);
    if (fm) {
      const file = resolveSkeletonToken(fm[1], sk.table).trim();
      if (file === '-') {
        // The message comes on stdin: in a shell command that is the heredoc body.
        if (sk.heredocKeys.length) for (const k of sk.heredocKeys) parts.push(sk.table[k]);
        else parts.push('');
      } else if (file && fs.existsSync(file)) parts.push(fs.readFileSync(file, 'utf8'));
      else parts.push('');
    }
  }
  if (parts.length === 0) return null;
  return { message: parts.join('\n'), what };
}

// Steps (collectSaveWorkMessage):
//   1. Take every string field whose name contains message, msg or commit.
//   2. With none, log drift and take every string field, so the field name gets learned.
//   3. Return the fields joined with newlines.
function collectSaveWorkMessage(ti, payload) {
  const named = Object.keys(ti).filter(k => typeof ti[k] === 'string' && /message|msg|commit/i.test(k)).map(k => ti[k]);
  if (named.length > 0) return named.join('\n');
  C.writeDrift(NAME, 'save_work has no message-named string field; read every string field', payload);
  return Object.keys(ti).filter(k => typeof ti[k] === 'string').map(k => ti[k]).join('\n');
}

// Steps (findTrailer):
//   1. A Verified: line at the start of any line wins; else a Verified: run on after the title on one line.
//   2. Return the trailer text and whether it is a bare none (none with no reason after it).
function findTrailer(message) {
  let trailer = null;
  let m = message.match(/^\s*Verified:\s*(\S[^\r\n]*)/im);
  if (!m) m = message.match(/\bVerified:\s*(\S[^\r\n]*)/i);
  if (m) trailer = m[1].trim();
  let noneBare = false;
  if (trailer && /^none\b/i.test(trailer) && !/^none\b\s*[-:;,.(]*\s*\S+/i.test(trailer)) noneBare = true;
  return { trailer, noneBare };
}

// Steps (main):
//   1. Payload, twin check, log path, mode; off exits 0.
//   2. Find the commit and its message for Bash/PowerShell or save_work; anything else exits 0.
//   3. Trailer; a usable one logs pass and exits 0.
//   4. No trailer: observe tells Claude and exits 0; enforce blocks, or passes after two blocks in the session.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);

  const logPath = process.env.COMMIT_VERIFY_GATE_LOG || path.join(C.stateDir(p), 'commit-verify-gate.log');
  const mode = readMode(p);
  if (mode === 'off') process.exit(0);

  const tool = String(p.tool_name || '');
  let message = null;
  let what = null;
  let command = null;

  if (tool === 'Bash' || tool === 'PowerShell') {
    const ti = p.tool_input;
    if (!ti || typeof ti !== 'object') { C.writeDrift(NAME, 'tool_input missing', p); process.exit(0); }
    if (!Object.prototype.hasOwnProperty.call(ti, 'command')) { C.writeDrift(NAME, 'tool_input.command missing', p); process.exit(0); }
    command = ti.command == null ? '' : String(ti.command);
    if (!command) process.exit(0);
    const found = collectShellMessage(command);
    if (!found) process.exit(0);
    message = found.message;
    what = found.what;
  } else if (tool === 'mcp__giteasy__save_work') {
    const ti = p.tool_input;
    if (!ti || typeof ti !== 'object') { C.writeDrift(NAME, 'tool_input missing', p); process.exit(0); }
    message = collectSaveWorkMessage(ti, p);
    what = 'GitEasy save_work';
    command = message;
  } else {
    process.exit(0);
  }

  const { trailer, noneBare } = findTrailer(message);
  const session = p.session_id ? String(p.session_id) : 'unknown';
  const cwd = p.cwd ? String(p.cwd) : 'unknown';

  if (trailer && !noneBare) {
    addGateLog(logPath, mode, 'pass', session, cwd, what, trailer, command);
    process.exit(0);
  }

  const hint = noneBare
    ? "'Verified: none' needs a reason after it, such as 'Verified: none - docs-only change'."
    : "Add one line to the end of the commit message itself: 'Verified: <what ran and what it showed>', or 'Verified: none - <reason>'. A shell comment does not count.";

  if (mode === 'observe') {
    addGateLog(logPath, mode, 'would-block', session, cwd, what, trailer, command);
    C.emit({ systemMessage: `Commit gate (observe mode): this ${what} carries no usable Verified: trailer. Logged as would-block in ${logPath}; in enforce mode it would be blocked. ${hint} The verify skill has the shapes.` });
    process.exit(0);
  }

  const priorBlocks = getSessionBlockCount(logPath, session);
  if (priorBlocks >= 2) {
    addGateLog(logPath, mode, 'pass-after-two-blocks', session, cwd, what, trailer, command);
    C.emit({ systemMessage: `Commit gate: this session was already blocked twice, so this ${what} passes without a Verified: trailer and is logged as unverified. The gate never wedges a session. ${hint}` });
    process.exit(0);
  }

  addGateLog(logPath, mode, 'blocked', session, cwd, what, trailer, command);
  C.block([
    `Commit gate (enforce): blocked this ${what}. The message has no usable Verified: trailer.`,
    '',
    'Every commit says how it was checked (CLAUDE.md section 15, verify skill). Run the',
    "repo's verify skill, then end the message with one line:",
    '',
    '  Verified: Pester 14/14 (GitEasy.savework.tests.ps1); verify: Save-Work on a scratch repo saw the commit',
    '  Verified: none - docs-only change, no code path touched',
    '',
    hint,
    `Block ${priorBlocks + 1} of 2 for this session; the third commit passes and is logged as unverified.`,
  ]);
}

C.run(main);
