// =============================================================================
// Script  : shell-command-guards.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/shell-command-guards.ps1
//                            (created 2026-08-15, checks 4 and 5 added 2026-10-06
//                            and 2026-10-21) for the portable kit. One PreToolUse
//                            guard for Bash|PowerShell commands, five checks in one
//                            process, cheapest first:
//                            1. Cloud delete scoping (feedback_azure_delete_named_only
//                               + project_clustervalidator_ecr_sole_artifact):
//                               blocks az group delete, az * delete --ids,
//                               tag-scoped az deletes, and aws ecr
//                               batch-delete-image/delete-repository.
//                               Escape: #keith-approved-delete.
//                            2. No new VS Code windows (feedback_no_new_vscode_windows):
//                               blocks `code <path>`. Escape: #code-ok.
//                            3. SqlBackupValidation tag gate
//                               (sqlbackupvalidation_ci_cd_strategy): git tag /
//                               push --tags in that repo needs the pre-interaction
//                               handshake. Escape: #sbv-handshake-ok.
//                            4. Azure PowerShell destructive-scope deletes
//                               (Remove-AzResourceGroup, pipeline-fed Remove-Az*,
//                               wildcard-name removes). Same escape as check 1.
//                            5. An az create/deploy/up that names no subscription
//                               is blocked: the CLI default stays on GreenPointWorks
//                               for unattended signing. Passes with --subscription
//                               or a full /subscriptions/ path. Escape: #az-sub-ok.
//                            Fail-open on any error per reference_hook_semantics.
// Steps:
//   1. Read the payload; fail open on anything unreadable. Step aside when the PowerShell twin exists.
//   2. Pass any tool other than Bash or PowerShell. Log drift and pass when tool_input.command is not a string.
//   3. Run checks 1 to 5 in order; the first hit blocks with exit 2 and its rule on stderr.
//   4. Nothing hit: exit 0.
// =============================================================================
'use strict';
const C = require('./lib/common');

const NAME = 'shell-command-guards';

// Steps (checkCloudDelete):
//   1. Skip when the command carries #keith-approved-delete.
//   2. Match az group delete, az ... delete --ids, az ... delete --tag, aws ecr batch-delete-image/delete-repository.
//   3. Return the block lines on a hit, else null.
function checkCloudDelete(cmd) {
  if (/#keith-approved-delete/.test(cmd)) return null;
  let reason = null;
  if (/\baz\s+group\s+delete\b/i.test(cmd)) reason = 'resource-GROUP-scope delete (az group delete)';
  else if (/\baz\b[^\r\n|;&]*\bdelete\b[^\r\n|;&]*--ids\b/i.test(cmd)) reason = 'bulk delete via --ids (query-driven, not named)';
  else if (/\baz\b[^\r\n|;&]*\bdelete\b[^\r\n|;&]*--tag\b/i.test(cmd)) reason = 'tag-scoped delete (not named)';
  else if (/\baws\s+ecr\s+(batch-delete-image|delete-repository)\b/i.test(cmd)) reason = 'ECR delete — clustervalidator:1.11.5 in ECR is the SOLE remaining container artifact (project_clustervalidator_ecr_sole_artifact)';
  if (!reason) return null;
  return [
    `Cloud-delete guard: BLOCKED — ${reason}.`,
    'Rule (feedback_azure_delete_named_only, HARD): never delete cloud resources by',
    'wildcard, tag, query, or group scope. Name each resource individually and get',
    "Keith's explicit approval, then append #keith-approved-delete to the command.",
  ];
}

// Steps (checkVsCode):
//   1. Skip when the command carries #code-ok.
//   2. Match `code <something>` at the start of the command or after ; & |, except --list, --version, --help, --diff.
//   3. Return the block lines on a hit, else null.
function checkVsCode(cmd) {
  if (/#code-ok/.test(cmd)) return null;
  if (!/(^|[;&|]\s*)code(\.cmd|\.exe)?\s+(?!--list|--version|--help|--diff\b)/i.test(cmd)) return null;
  return [
    'VS Code guard: BLOCKED — never open new VS Code windows (feedback_no_new_vscode_windows).',
    '"Open X" means read it in context. If Keith explicitly asked for a window, append #code-ok.',
  ];
}

// Steps (checkSbvTag):
//   1. Skip when the command carries #sbv-handshake-ok.
//   2. The command touches SqlBackupValidation when its text or the payload cwd names it.
//   3. In that repo, git tag or git push ... --tags blocks. Return the lines, else null.
function checkSbvTag(cmd, payload) {
  if (/#sbv-handshake-ok/.test(cmd)) return null;
  const touchesSbv = /SqlBackupValidation/i.test(cmd) || (typeof payload.cwd === 'string' && /SqlBackupValidation/i.test(payload.cwd));
  if (!(touchesSbv && /\bgit\b[^\r\n]*\b(tag\b|push\b[^\r\n]*--tags)/i.test(cmd))) return null;
  return [
    'SBV tag gate: BLOCKED — sqlbackupvalidation_ci_cd_strategy requires the explicit',
    'pre-interaction handshake with Keith before any commit/tag that can promote a build.',
    'Complete the handshake, then append #sbv-handshake-ok.',
  ];
}

// Steps (checkAzPowerShellDelete):
//   1. Skip when the command carries #keith-approved-delete.
//   2. Match Remove-AzResourceGroup, a pipeline into Remove-Az*, or a Remove-Az* whose -Name/-ResourceName/-ResourceGroupName holds a wildcard.
//   3. Return the block lines on a hit, else null. Named single-resource removes pass.
function checkAzPowerShellDelete(cmd) {
  if (/#keith-approved-delete/.test(cmd)) return null;
  let reason = null;
  if (/\bRemove-AzResourceGroup\b/i.test(cmd)) reason = 'resource-GROUP-scope delete (Remove-AzResourceGroup)';
  else if (/\|\s*Remove-Az\w+/i.test(cmd)) reason = 'pipeline-fed delete (Get-Az... | Remove-Az...) — query-driven, not named';
  else if (/\bRemove-Az\w+\b[^\r\n|;&]*-(Name|ResourceName|ResourceGroupName)\s+["']?[^"'\s]*\*/i.test(cmd)) reason = 'wildcard-name delete (Remove-Az... -Name *)';
  if (!reason) return null;
  return [
    `Cloud-delete guard: BLOCKED — ${reason}.`,
    'Rule (feedback_azure_delete_named_only, HARD): never delete Azure resources by',
    'wildcard, pipeline/query, or resource-group scope. Name each resource individually',
    "and get Keith's explicit approval, then append #keith-approved-delete to the command.",
  ];
}

// Steps (checkAzSubscription):
//   1. Skip when the command carries #az-sub-ok.
//   2. Join continued lines (backtick or backslash before a newline), split on newlines ; | &.
//   3. For each segment with `az `: skip tenant-level and tooling groups; skip when no create/deploy/up word; skip when --subscription or /subscriptions/ is present.
//   4. Any segment left blocks. Return the lines, else null.
function checkAzSubscription(cmd) {
  if (/#az-sub-ok/.test(cmd)) return null;
  const joined = cmd.replace(/[`\\]\r?\n/g, ' ');
  for (const seg of joined.split(/[\r\n;|&]/)) {
    if (!/\baz\s+/i.test(seg)) continue;
    if (/\baz\s+(ad|account|config|extension|login|logout|cloud|version|upgrade|bicep|devops|boards|repos|pipelines|artifacts)\b/i.test(seg)) continue;
    if (!/\s(create|deploy|up)(\s|$)/i.test(seg)) continue;
    if (/--subscription\b/i.test(seg) || /\/subscriptions\//i.test(seg)) continue;
    return [
      'Azure subscription guard: BLOCKED. This az create/deploy names no subscription, so it',
      'would land in the CLI default, GreenPointWorks - Sponsored Credits. CLAUDE.md s20: build',
      'in Detent Point - Production. Add --subscription "Detent Point - Production" (the CI VM',
      'and signing exceptions take --subscription "GreenPointWorks - Sponsored Credits"). If',
      'the command cannot take --subscription, append #az-sub-ok.',
    ];
  }
  return null;
}

// Steps (main):
//   1. Payload, twin check, tool scope.
//   2. Command must be a non-empty string; a missing one on an in-scope tool logs drift.
//   3. Run the five checks in order; block on the first hit; else exit 0.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (p.tool_name !== 'Bash' && p.tool_name !== 'PowerShell') process.exit(0);
  const ti = p.tool_input;
  if (!ti || typeof ti !== 'object' || typeof ti.command !== 'string') {
    C.writeDrift(NAME, 'tool_input.command missing', p);
    process.exit(0);
  }
  const cmd = ti.command;
  if (!cmd) process.exit(0);

  for (const check of [checkCloudDelete, checkVsCode, (c) => checkSbvTag(c, p), checkAzPowerShellDelete, checkAzSubscription]) {
    const lines = check(cmd);
    if (lines) C.block(lines);
  }
  process.exit(0);
}

C.run(main);
