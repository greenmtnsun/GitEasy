// =============================================================================
// Script  : pre-compact-checkpoint.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            hooks/pre-compact-checkpoint.ps1 for the portable
//                            kit. PreCompact hook: saves the git state (branch,
//                            uncommitted count, last five commits, first 30
//                            changed files) to PROGRESS.md in the working
//                            directory before context compaction.
//                            session-start-context.js surfaces it in the next
//                            session while it is under 24 hours old. Outside a
//                            git repo it does nothing. Fail-open on anything
//                            unexpected.
// Steps:
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Ask git for the current branch; exit 0 when there is none (not a repo, or git missing).
//   3. Collect the short status and the last five commits.
//   4. Write PROGRESS.md in the working directory with the checkpoint.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const C = require('./lib/common');

const HOOK = 'pre-compact-checkpoint';

// Steps (git):
//   1. Run git with the given args in the working directory and return stdout's non-blank lines.
//   2. [] when git is missing or the command fails.
function git(args) {
  const r = spawnSync('git', args, { encoding: 'utf8' });
  if (r.error || r.status !== 0) return [];
  return (r.stdout || '').split(/\r?\n/).filter(l => /\S/.test(l));
}

// Steps (stamp):
//   1. Format the local time as yyyy-MM-dd HH:mm:ss, the shape the PowerShell original wrote.
function stamp(d) {
  const z = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${z(d.getMonth() + 1)}-${z(d.getDate())} ${z(d.getHours())}:${z(d.getMinutes())}:${z(d.getSeconds())}`;
}

// Steps (main):
//   1. Read the payload and the branch; nothing to save without a branch.
//   2. Build the checkpoint lines and write PROGRESS.md in the working directory.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(HOOK)) process.exit(0);

  const branch = git(['branch', '--show-current'])[0];
  if (!branch) process.exit(0);

  const statusLines = git(['status', '--short']);
  const recent = git(['log', '--oneline', '-5']);

  let lines = [
    '# Compaction Checkpoint',
    `Saved: ${stamp(new Date())}`,
    '',
    `Branch: ${branch} | Uncommitted: ${statusLines.length} files`,
    '',
    '## Recent commits',
  ].concat(recent);

  if (statusLines.length > 0) {
    lines = lines.concat(['', '## Uncommitted changes (first 30)'], statusLines.slice(0, 30));
  }

  fs.writeFileSync(path.join(process.cwd(), 'PROGRESS.md'), lines.join('\n') + '\n', 'utf8');
  process.exit(0);
}

C.run(main);
