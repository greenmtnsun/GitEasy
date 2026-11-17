// =============================================================================
// Script  : common.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Shared helpers for the portable
//                            (Node) hook kit that travels with each repo under
//                            .claude/hooks. The PowerShell hooks in
//                            C:\Users\keith\.claude\hooks stay the PC originals;
//                            these ports exist so cloud and phone sessions get
//                            the same rules. Every hook: reads one JSON payload
//                            from stdin, fails open on anything unreadable,
//                            steps aside on Keith's PC when its PowerShell twin
//                            exists, exits 0 to pass or 2 to block with the
//                            reason on stderr, and may print one JSON object on
//                            stdout (systemMessage, hookSpecificOutput).
// =============================================================================
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

// Steps (readPayload):
//   1. Read all of stdin as UTF-8.
//   2. Parse it as JSON; return null on empty or malformed input so the caller fails open.
function readPayload() {
  let raw = '';
  try { raw = fs.readFileSync(0, 'utf8'); } catch { return null; }
  if (!raw || !raw.trim()) return null;
  try { return JSON.parse(raw); } catch { return null; }
}

// Steps (hasPowerShellTwin):
//   1. Only on Windows: look for C:\Users\<user>\.claude\hooks\<name>.ps1.
//   2. True when it exists, which means the PC's own hook already enforces this rule.
function hasPowerShellTwin(name) {
  if (process.platform !== 'win32') return false;
  try { return fs.existsSync(path.join(os.homedir(), '.claude', 'hooks', `${name}.ps1`)); } catch { return false; }
}

// Steps (projectDir):
//   1. Prefer CLAUDE_PROJECT_DIR, which Claude Code sets for hook commands.
//   2. Else the payload's cwd, else the process cwd.
function projectDir(payload) {
  return process.env.CLAUDE_PROJECT_DIR || (payload && payload.cwd) || process.cwd();
}

// Steps (stateDir):
//   1. KIT_STATE_DIR when set (tests point it at a scratch folder).
//   2. Else <home>/.claude/kit-state/<repo folder name>, created on demand. Never inside the repo tree.
function stateDir(payload) {
  const base = process.env.KIT_STATE_DIR || path.join(os.homedir(), '.claude', 'kit-state', path.basename(projectDir(payload)));
  try { fs.mkdirSync(base, { recursive: true }); } catch { }
  return base;
}

// Steps (appendJsonLine):
//   1. Serialise the entry on one line and append it with a newline, UTF-8 without BOM.
//   2. Swallow any failure: logging never changes a hook's answer.
function appendJsonLine(file, entry) {
  try { fs.appendFileSync(file, JSON.stringify(entry) + '\n', 'utf8'); } catch { }
}

// Steps (writeDrift):
//   1. Record that the payload shape was not what the hook expected, in drift.log under the state dir.
//   2. drift-surface reads and clears that file at Stop.
function writeDrift(hookName, reason, payload) {
  appendJsonLine(path.join(stateDir(payload), 'drift.log'), {
    Timestamp: new Date().toISOString(), Hook: hookName, Reason: reason,
    Payload: safeJson(payload),
  });
}

// Steps (safeJson): stringify a value for a log line, falling back to String() when it cannot be serialised.
function safeJson(v) { try { return JSON.stringify(v); } catch { return String(v); } }

// Steps (block):
//   1. Write the message lines to stderr.
//   2. Exit 2, which Claude Code reads as "blocked, show Claude the stderr".
function block(lines) {
  process.stderr.write((Array.isArray(lines) ? lines : [lines]).join('\n') + '\n');
  process.exit(2);
}

// Steps (emit):
//   1. Print one compact JSON object on stdout for Claude Code (systemMessage, hookSpecificOutput).
function emit(obj) { process.stdout.write(JSON.stringify(obj)); }

// Steps (editedText):
//   1. For Edit, the new_string; for Write, the content; MultiEdit joins each edit's new_string.
//   2. Null when the field is missing, so the caller can log drift.
function editedText(payload) {
  const ti = payload && payload.tool_input;
  if (!ti) return null;
  if (payload.tool_name === 'Write') return typeof ti.content === 'string' ? ti.content : null;
  if (payload.tool_name === 'Edit') return typeof ti.new_string === 'string' ? ti.new_string : null;
  if (payload.tool_name === 'MultiEdit' && Array.isArray(ti.edits)) return ti.edits.map(e => e.new_string || '').join('\n');
  return null;
}

// Steps (readTail):
//   1. Open the file for reading while another process holds it, and take the last `bytes` bytes.
//   2. Return the text, or '' when the file is missing or empty.
function readTail(file, bytes) {
  let fd;
  try {
    const size = fs.statSync(file).size;
    if (!size) return '';
    const take = Math.min(size, bytes);
    fd = fs.openSync(file, 'r');
    const buf = Buffer.alloc(take);
    fs.readSync(fd, buf, 0, take, size - take);
    return buf.toString('utf8');
  } catch { return ''; } finally { if (fd !== undefined) { try { fs.closeSync(fd); } catch { } } }
}

// Steps (run):
//   1. Run the hook body; any thrown error exits 0 (fail open), per reference_hook_semantics.
function run(body) {
  try { body(); } catch { process.exit(0); }
}

module.exports = { readPayload, hasPowerShellTwin, projectDir, stateDir, appendJsonLine, writeDrift, block, emit, editedText, readTail, run };
