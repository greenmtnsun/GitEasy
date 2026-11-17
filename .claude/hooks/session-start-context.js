// =============================================================================
// Script  : session-start-context.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            hooks/session-start-context.ps1 for the portable
//                            kit. SessionStart hook; plain stdout is injected
//                            into Claude's context. Prints the branch /
//                            uncommitted / recent-commits line, the official
//                            delivery process ledger line (Docs/PIPELINE.md or
//                            docs/PIPELINE.md; the "no ledger" warning fires only
//                            when the repo has a Docs or docs folder) and a
//                            PROGRESS.md compaction checkpoint under 24 hours old.
//                            The Ollama status line is PC-only and not ported.
//                            New here: in a cloud session (CLAUDE_CODE_REMOTE=true)
//                            the file <projectDir>/.claude/CLAUDE-global.md, the
//                            kit's copy of Keith's global CLAUDE.md, is printed
//                            into context, since the PC loads it as its user-level
//                            CLAUDE.md and the cloud does not. Steps aside on the
//                            PC when the PowerShell twin exists, as every kit hook
//                            does. Fail-open on anything unexpected.
// Steps:
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. In a cloud session, print .claude/CLAUDE-global.md between === markers when it exists.
//   3. Print "Branch: X | Uncommitted: N files | Recent: ..." from git; stop when there is no branch.
//   4. Print the delivery ledger line, or the no-ledger warning when the repo has a Docs/docs folder.
//   5. Print PROGRESS.md as an overnight checkpoint when it is under 24 hours old.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const C = require('./lib/common');

const HOOK = 'session-start-context';
const out = [];

// Steps (git):
//   1. Run git with the given args in the working directory and return stdout's non-blank lines.
//   2. [] when git is missing or the command fails.
function git(args) {
  const r = spawnSync('git', args, { encoding: 'utf8' });
  if (r.error || r.status !== 0) return [];
  return (r.stdout || '').split(/\r?\n/).filter(l => /\S/.test(l));
}

// Steps (ymd):
//   1. Format a date as yyyy-MM-dd in local time.
function ymd(d) {
  const z = n => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${z(d.getMonth() + 1)}-${z(d.getDate())}`;
}

// Steps (printGlobalRules):
//   1. Only in a cloud session (CLAUDE_CODE_REMOTE=true); the PC loads its own CLAUDE.md.
//   2. When <projectDir>/.claude/CLAUDE-global.md exists, print the header, its contents and a closing ===.
function printGlobalRules(payload) {
  if (process.env.CLAUDE_CODE_REMOTE !== 'true') return;
  const file = path.join(C.projectDir(payload), '.claude', 'CLAUDE-global.md');
  let text;
  try { text = fs.readFileSync(file, 'utf8'); } catch { return; }
  out.push('=== Global rules (CLAUDE-global.md, injected because this is a cloud session) ===');
  out.push(text.replace(/\r?\n$/, ''));
  out.push('===');
}

// Steps (printLedger):
//   1. Find the repo root; nothing outside a git repo.
//   2. With Docs/PIPELINE.md or docs/PIPELINE.md: print its modified date and the count of "Not done" rows.
//   3. With a Docs or docs folder but no ledger: print the official-delivery-process UNKNOWN warning.
function printLedger() {
  const repoRoot = git(['rev-parse', '--show-toplevel'])[0];
  if (!repoRoot) return;
  let hasFolder = false;
  for (const folder of ['Docs', 'docs']) {
    const dir = path.join(repoRoot, folder);
    if (!fs.existsSync(dir)) continue;
    hasFolder = true;
    const ledger = path.join(dir, 'PIPELINE.md');
    if (!fs.existsSync(ledger)) continue;
    const text = fs.readFileSync(ledger, 'utf8');
    const notDone = text.split(/\r?\n/).filter(l => /\|\s*Not done/.test(l)).length;
    const mod = ymd(fs.statSync(ledger).mtime);
    out.push(`Delivery ledger: ${folder}/PIPELINE.md | modified ${mod} | 'Not done' rows: ${notDone}`);
    return;
  }
  if (hasFolder) {
    out.push('No Docs/PIPELINE.md in this repo - official delivery process status UNKNOWN. Create the ledger (delivery-pipeline skill) before any ship-phase claim.');
  }
}

// Steps (printCheckpoint):
//   1. When PROGRESS.md in the working directory is under 24 hours old, print it between === markers.
function printCheckpoint() {
  const progressPath = path.join(process.cwd(), 'PROGRESS.md');
  if (!fs.existsSync(progressPath)) return;
  const ageHours = (Date.now() - fs.statSync(progressPath).mtimeMs) / 3600000;
  if (ageHours >= 24) return;
  out.push('');
  out.push('=== Overnight checkpoint found (PROGRESS.md) ===');
  out.push(fs.readFileSync(progressPath, 'utf8').replace(/\r?\n$/, ''));
  out.push('===');
}

// Steps (flush):
//   1. Write the collected lines to stdout, one per line, and exit 0.
function flush() {
  if (out.length) process.stdout.write(out.join('\n') + '\n');
  process.exit(0);
}

// Steps (main):
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Global rules first (cloud only), then the git line, the ledger line and the checkpoint.
//   3. Each part fails on its own so one missing piece never hides the others.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(HOOK)) process.exit(0);

  try { printGlobalRules(p); } catch { }

  const branch = git(['branch', '--show-current'])[0];
  if (!branch) flush();

  const statusCount = git(['status', '--short']).length;
  const recent = git(['log', '--oneline', '-3']);
  const recentStr = recent.length ? ` | Recent: ${recent.join(' / ')}` : '';
  out.push(`Branch: ${branch} | Uncommitted: ${statusCount} files${recentStr}`);

  try { printLedger(); } catch { }
  try { printCheckpoint(); } catch { }
  flush();
}

C.run(main);
