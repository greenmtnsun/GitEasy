// =============================================================================
// Script  : pipeline-gate-stop.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            hooks/pipeline-gate-stop.ps1 for the portable kit.
//                            Stop hook for the delivery-pipeline skill's Ship-phase
//                            gate. A reply that claims a production deploy or a
//                            publish to one of Keith's real ship channels
//                            (PSGallery, NuGet, Microsoft Store, Play, Azure,
//                            detentpoint.com, AWS/Azure Marketplace, Bedrock) must
//                            carry either <!-- pipeline-complete: ... --> naming
//                            all seven phases, backed by a Docs/PIPELINE.md ledger
//                            that moved in the last 14 days, or a break-glass
//                            <!-- pipeline-exception: reason --> that is logged to
//                            pipeline-exceptions.log under the kit state dir and
//                            announced on stderr. Bare "is live" never fires. The
//                            final reply comes from last_assistant_message; the
//                            transcript's end is the fallback, logged as drift. The
//                            ledger is looked up under the git top level of the
//                            payload's cwd, as Docs/ or docs/; a missing git
//                            fails open. Fail-open on anything unexpected.
// Steps:
//   1. Read the Stop payload; fail open on anything unreadable or without a transcript.
//   2. Take the final reply from last_assistant_message. If it is missing, log drift
//      and use the last reply in the transcript's current turn instead.
//   3. Pass a reply with no production-deploy claim.
//   4. Pass a claim whose pipeline-complete marker names all seven phases and whose
//      repo ledger moved in the last 14 days; block a marker that falls short.
//   5. Pass a claim with a pipeline-exception reason, logging and announcing it.
//   6. Otherwise block (exit 2) with the marker shapes.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const C = require('./lib/common');
const T = require('./lib/transcript');

const HOOK = 'pipeline-gate-stop';

// Production-deploy claim trigger. Deliberately narrower than no-stealth-completion-stop's
// broad completion-word set: only the highest-stakes Ship-phase claims, on Keith's real
// ship channels, never a bare "is live"/"went live". Same pattern as the PowerShell original.
const prodPattern = /\b(deployed to prod(uction)?|live in prod(uction)?|pushed to prod(uction)?|shipped to prod(uction)?|prod(uction)?\s+(deploy(ment)?|release)\s+(complete|done|finished)|production is (live|updated)|published to (the )?(PSGallery|PowerShell Gallery|NuGet|Microsoft Store|Play (Store|Console)|detentpoint(\.com)?|keith-ramsey(\.com)?|(our|the) (web)?site)|(published|live) on (detentpoint(\.com)?|keith-ramsey(\.com)?|(our|the) (web)?site)|(site|website|wiki|wikis|docs|documentation)\s+(publish|deploy)(ed|ment)?\s+(complete|done|live)|deployed to (the )?Azure|submission (submitted|complete)|(store|gallery|registry|marketplace)\s+(publish|release|submission)\s+(complete|done|live)|published to (the )?(AWS Marketplace|Azure Marketplace|Bedrock)|(AWS |Azure )?marketplace (listing|offer) (is (now )?|went |has gone )(live|published)|marketplace (listing|offer) published|(marketplace )?(listing|offer) (is (now )?|has been )published|pressed Go[- ]?live)\b/i;

const PHASES = ['Discovery', 'Design', 'Build', 'Verify', 'Document', 'Ship', 'Operate'];

// Steps (findLedger):
//   1. Resolve the git top level of cwd; null when cwd is missing, not a repo, or git is absent.
//   2. Return { repoRoot, ledger } where ledger is Docs/PIPELINE.md or docs/PIPELINE.md if present, else null.
function findLedger(cwd) {
  if (!cwd || typeof cwd !== 'string' || !fs.existsSync(cwd)) return null;
  const r = spawnSync('git', ['-C', cwd, 'rev-parse', '--show-toplevel'], { encoding: 'utf8' });
  if (r.error || r.status !== 0) return null;
  const repoRoot = (r.stdout || '').trim();
  if (!repoRoot) return null;
  for (const folder of ['Docs', 'docs']) {
    const candidate = path.join(repoRoot, folder, 'PIPELINE.md');
    if (fs.existsSync(candidate)) return { repoRoot, ledger: candidate };
  }
  return { repoRoot, ledger: null };
}

// Steps (checkLedger):
//   1. With a repo root and no ledger: block, the marker asserts what the disk cannot corroborate.
//   2. With a ledger older than 14 days: block, the ship claim rides a stale ledger.
//   3. Anything else (no cwd, no repo, no git) passes; the check fails open.
function checkLedger(cwd) {
  let info;
  try { info = findLedger(cwd); } catch { return; }
  if (!info) return;
  if (!info.ledger) {
    C.block([
      'Pipeline gate: ship claim with a pipeline-complete marker, but this repo has',
      'NO Docs/PIPELINE.md ledger on disk. The marker asserts phases the ledger',
      'cannot corroborate. Create/update the ledger (delivery-pipeline skill), then re-emit.',
    ]);
  }
  let ageDays;
  try { ageDays = (Date.now() - fs.statSync(info.ledger).mtimeMs) / 86400000; } catch { return; }
  if (ageDays > 14) {
    C.block([
      `Pipeline gate: Docs/PIPELINE.md last moved ${Math.round(ageDays)} days ago - a ship`,
      'claim is riding a stale ledger. Update the ledger rows for THIS work, then re-emit.',
    ]);
  }
}

// Steps (main):
//   1. Read the payload; step aside on the PC where the PowerShell twin runs.
//   2. Resolve the final reply (payload field first, transcript tail second); pass when no ship claim.
//   3. A filled pipeline-complete marker must name all seven phases and agree with the ledger.
//   4. A pipeline-exception reason is logged and announced, then passes.
//   5. Otherwise block with the marker shapes.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(HOOK)) process.exit(0);

  if (!Object.prototype.hasOwnProperty.call(p, 'transcript_path')) process.exit(0);
  const transcript = p.transcript_path;
  if (typeof transcript !== 'string' || !fs.existsSync(transcript)) process.exit(0);

  // The final reply comes with the payload; the transcript may not hold it yet.
  let lastText = null;
  if (Object.prototype.hasOwnProperty.call(p, 'last_assistant_message')) {
    lastText = p.last_assistant_message == null ? '' : String(p.last_assistant_message);
  } else {
    C.writeDrift(HOOK, 'last_assistant_message missing; read the transcript end instead', p);
    try { lastText = T.getCurrentTurn(transcript).lastText; } catch { process.exit(0); }
  }

  if (!lastText) process.exit(0);
  if (!prodPattern.test(lastText)) process.exit(0);

  const completeMatch = /<!--\s*pipeline-complete\s*:\s*(.+?)\s*-->/s.exec(lastText);
  const exceptionMatch = /<!--\s*pipeline-exception\s*:\s*(.+?)\s*-->/.exec(lastText);

  if (completeMatch && completeMatch[1].trim()) {
    // (a) The marker must name all seven phases: a phase you cannot name is a phase you skipped.
    const markerText = completeMatch[1];
    const missing = PHASES.filter(ph => !new RegExp('\\b' + ph, 'i').test(markerText));
    if (missing.length > 0) {
      C.block([
        'Pipeline gate: pipeline-complete marker does not name every phase.',
        `Missing: ${missing.join(', ')}. Each of the seven phases needs an explicit`,
        'status — done, not applicable, or not done — inside the marker (CLAUDE.md §13).',
      ]);
    }
    // (b) The ledger must exist in the working repo and have moved during the work.
    checkLedger(p.cwd);
    process.exit(0);
  }

  if (exceptionMatch) {
    const reason = exceptionMatch[1].trim();
    if (reason) {
      const exceptionLogPath = path.join(C.stateDir(p), 'pipeline-exceptions.log');
      C.appendJsonLine(exceptionLogPath, {
        Timestamp: new Date().toISOString(),
        Reason: reason,
        Transcript: transcript,
      });
      process.stderr.write([
        '',
        '=== PIPELINE EXCEPTION INVOKED ===',
        `Reason: ${reason}`,
        `Logged to: ${exceptionLogPath}`,
        '',
      ].join('\n') + '\n');
      process.exit(0);
    }
  }

  C.block([
    'Pipeline gate: production-deploy claim without a pipeline marker.',
    '',
    'Your last assistant turn claimed a production deploy but included',
    'neither a <!-- pipeline-complete: ... --> marker with real content nor a',
    '<!-- pipeline-exception: reason --> marker.',
    '',
    'Per the delivery-pipeline skill, a production-deploy claim must carry one:',
    '',
    '  <!-- pipeline-complete: Discovery=done, Design=done, Build=done,',
    '       Verify=done, Document=done, Ship=this, Operate=done/disclosed -->',
    '  A bare <!-- pipeline-complete --> tag is no longer enough — say which',
    '  phases actually ran, in one pass, not drip-fed over several turns.',
    '',
    '  <!-- pipeline-exception: one-line reason -->',
    '  (break-glass — e.g. an active production incident. Never silent:',
    '  this marker is logged and surfaced every time it is used.)',
  ]);
}

C.run(main);
