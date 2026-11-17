// =============================================================================
// Script  : ps-parse-check.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of ps-parse-check.ps1
//                            (Output-Validity Contract) for the portable kit.
//                            PostToolUse on Write|Edit|MultiEdit: any
//                            .ps1/.psm1/.psd1 Claude writes MUST parse. Node
//                            cannot parse PowerShell, so when `pwsh` is on
//                            PATH the hook runs the same
//                            Parser.ParseInput check through it and blocks
//                            (exit 2) with the same message so the SAME turn
//                            fixes it. No pwsh means no check: exit 0
//                            silently. Fail-open on any other error.
// =============================================================================
'use strict';
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'ps-parse-check';
const IN_SCOPE_TOOLS = ['Write', 'Edit', 'MultiEdit'];

// The file path travels in an environment variable so no quoting of the path is needed.
const PWSH_SCRIPT = [
  '$ErrorActionPreference = "Stop"',
  '$content = Get-Content -LiteralPath $env:PS_PARSE_CHECK_FILE -Raw',
  'if ($null -eq $content) { $content = "" }',
  '$errors = $null',
  '[void][System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$errors)',
  '$first = @(foreach ($e in @($errors | Select-Object -First 5)) { @{ Line = $e.Extent.StartLineNumber; Col = $e.Extent.StartColumnNumber; Message = $e.Message } })',
  '@{ Count = @($errors).Count; First = $first } | ConvertTo-Json -Compress -Depth 4',
].join('; ');

// Steps (parseWithPwsh):
//   1. Run pwsh -NoProfile -Command with the ParseInput script; the file path goes in PS_PARSE_CHECK_FILE.
//   2. Return null when pwsh is absent (spawn error), times out, exits non-zero, or prints no JSON: the caller fails open.
//   3. Otherwise return { Count, First: [{ Line, Col, Message }] }.
function parseWithPwsh(absPath) {
  const r = spawnSync('pwsh', ['-NoProfile', '-NonInteractive', '-Command', PWSH_SCRIPT], {
    env: Object.assign({}, process.env, { PS_PARSE_CHECK_FILE: absPath }),
    encoding: 'utf8', timeout: 60000, windowsHide: true,
  });
  if (r.error || r.status !== 0 || !r.stdout) return null;
  try { return JSON.parse(r.stdout.trim()); } catch { return null; }
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Only Write, Edit and MultiEdit matter; exit 0 without a .ps1/.psm1/.psd1 file_path or when the file is missing.
//   3. Parse through pwsh; no pwsh or no answer exits 0 silently.
//   4. Any parse error blocks with the leaf name, the error count and up to five line/col/message details.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (!IN_SCOPE_TOOLS.includes(p.tool_name)) process.exit(0);
  const filePath = p.tool_input && p.tool_input.file_path;
  if (!filePath || typeof filePath !== 'string' || !filePath.trim()) process.exit(0);
  if (!/\.ps(m|d)?1$/i.test(filePath)) process.exit(0);
  const abs = S.resolvePath(filePath, p);
  if (!fs.existsSync(abs)) process.exit(0);

  const result = parseWithPwsh(abs);
  if (!result || !result.Count) process.exit(0);

  const first = Array.isArray(result.First) ? result.First : (result.First ? [result.First] : []);
  const detail = first.map(e => `  line ${e.Line} col ${e.Col}: ${e.Message}`);
  C.block([
    `Output-Validity gate: ${path.basename(abs)} does not parse (${result.Count} parse error(s)). The PowerShell just written is invalid and would not run. Fix it before continuing:`,
    detail.join('\n'),
  ]);
});
