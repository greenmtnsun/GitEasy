// =============================================================================
// Script  : air-gap-sentinel.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of air-gap-sentinel.ps1
//                            (2026-05-07..09) for the portable kit. PreToolUse
//                            on Edit, Write and MultiEdit: blocks saves of
//                            .ps1/.psm1/.psd1/.json/.yaml/.yml files inside the
//                            project dir that contain a UNC path with a named
//                            host, a non-loopback IPv4 (RFC 5737 docs ranges
//                            exempt), an IPv6 address (::1, fe80::/10 and
//                            2001:db8::/32 exempt; ULA flagged as private), or
//                            a bare hostname bound to a network-target
//                            parameter. Tests\Fixtures is exempt. Payload-shape
//                            drift is logged and the hook still exits 0.
//                            Scope change from the PC original: "inside the
//                            project dir" replaces C:\Sysadmin\Scripts\.
// =============================================================================
'use strict';
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'air-gap-sentinel';
const IN_SCOPE_TOOLS = ['Edit', 'Write', 'MultiEdit'];
const CONTENT_FIELD = { Edit: 'new_string', Write: 'content', MultiEdit: 'edits' };

// Steps (findUnc):
//   1. Match \\HOSTNAME\share where the host starts with a letter and is at least 2 chars.
//   2. Report each with its offset.
function findUnc(content, findings) {
  for (const m of content.matchAll(/\\\\[A-Za-z][A-Za-z0-9-]+\\/g)) {
    findings.push(`UNC path leak: '${m[0]}' at offset ${m.index}`);
  }
}

// Steps (findIpv4):
//   1. Match dotted quads with each octet 0-255.
//   2. Skip loopback, 0.x, link-local, broadcast and the RFC 5737 documentation ranges.
//   3. Report RFC 1918 ranges as private, everything else as public.
function findIpv4(content, findings) {
  const rx = /\b(?:25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])(?:\.(?:25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])){3}\b/g;
  for (const m of content.matchAll(rx)) {
    const ip = m[0];
    if (/^(127\.|0\.|169\.254\.|255\.255\.255\.255$)/.test(ip)) continue;
    if (/^(192\.0\.2\.|198\.51\.100\.|203\.0\.113\.)/.test(ip)) continue;
    if (/^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)/.test(ip)) findings.push(`Private IPv4 leak (RFC1918): '${ip}'`);
    else findings.push(`Public IPv4 leak: '${ip}'`);
  }
}

// Steps (findIpv6):
//   1. Match full 8-group and the three compressed (::) forms; the lookbehind excludes ]:: (PS [Type]::Method) and word/colon splices.
//   2. Skip ::1, link-local fe80::/10 and the RFC 3849 docs prefix 2001:db8::/32.
//   3. Report fc00::/7 as ULA (private), everything else as public.
function findIpv6(content, findings) {
  const patterns = [
    /(?<![\w:\]])(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}(?![\w:])/g,
    /(?<![\w:\]])(?:[0-9a-fA-F]{1,4}:){1,7}:(?![\w:])/g,
    /(?<![\w:\]])::(?:[0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}(?![\w:])/g,
    /(?<![\w:\]])(?:[0-9a-fA-F]{1,4}:){1,6}(?::[0-9a-fA-F]{1,4})+(?![\w:])/g,
  ];
  for (const rx of patterns) {
    for (const m of content.matchAll(rx)) {
      const ip = m[0].toLowerCase();
      if (ip === '::1') continue;
      if (/^fe[89ab][0-9a-f]?:/.test(ip)) continue;
      if (/^2001:0?db8:/.test(ip)) continue;
      if (/^f[cd][0-9a-f]{2}:/.test(ip)) findings.push(`Private IPv6 leak (ULA): '${m[0]}'`);
      else findings.push(`Public IPv6 leak: '${m[0]}'`);
    }
  }
}

// Steps (findHostnames):
//   1. Match a quoted string literal bound to -SqlInstance, -SqlServer, -ComputerName, -Server, -Computer, -Host or -Hostname.
//   2. Skip variable expansions, . and .., wildcards, dotted quads (IPv4 is handled above) and placeholder names.
//   3. Report the rest as hostname leaks. Positional args, splatting and connection strings are not caught.
function findHostnames(content, findings) {
  const netParamRx = /(?<![A-Za-z0-9_-])-(SqlInstance|SqlServer|ComputerName|Server|Computer|Host|Hostname)\s+(['"])([^'"]+)\2/gi;
  const placeholderRx = /^(localhost|\(local\)|example\.com|example\.org|server01|server02|sqlserver01|host|hostname|computername)$/i;
  for (const m of content.matchAll(netParamRx)) {
    const param = m[1];
    const value = m[3];
    if (/^\$/.test(value)) continue;
    if (/^\.\.?\\?$/.test(value)) continue;
    if (/\*/.test(value)) continue;
    if (/^\d+\.\d+\.\d+\.\d+$/.test(value)) continue;
    if (placeholderRx.test(value)) continue;
    findings.push(`Hostname leak: -${param} '${value}'`);
  }
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Only Edit, Write and MultiEdit matter. Log drift and exit 0 when tool_input or file_path is missing.
//   3. Exit 0 for files outside the project dir, without a .ps1/.psm1/.psd1/.json/.yaml/.yml extension, or under Tests\Fixtures.
//   4. Log drift and exit 0 when the content field for the tool is missing; exit 0 on empty content.
//   5. Run the four leak checks; exit 0 with no findings, else block with the original wording.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  const tool = p.tool_name;
  if (!IN_SCOPE_TOOLS.includes(tool)) process.exit(0);
  if (!p.tool_input) { C.writeDrift(NAME, 'tool_input missing', p); process.exit(0); }
  if (!Object.prototype.hasOwnProperty.call(p.tool_input, 'file_path')) { C.writeDrift(NAME, 'tool_input.file_path missing', p); process.exit(0); }
  const filePath = p.tool_input.file_path;
  if (!filePath) process.exit(0);

  const scope = S.inProject(filePath, p);
  if (!scope) process.exit(0);
  if (!/\.(ps1|psm1|psd1|json|yaml|yml)$/i.test(filePath)) process.exit(0);
  if (S.isTestFixture(scope)) process.exit(0);

  const content = C.editedText(p);
  if (content === null) { C.writeDrift(NAME, `tool_input.${CONTENT_FIELD[tool]} missing`, p); process.exit(0); }
  if (!content) process.exit(0);

  const findings = [];
  findUnc(content, findings);
  findIpv4(content, findings);
  findIpv6(content, findings);
  findHostnames(content, findings);
  if (findings.length === 0) process.exit(0);

  C.block([
    `Air-gap sentinel: blocked save to ${filePath}`,
    '',
    'Suite source must be portable across environments. Found:',
    ...findings.map(f => `  ${f}`),
    '',
    'Replace with placeholders, parameters, or registered config settings.',
    'Documentation IPs: 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 (RFC 5737); 2001:db8::/32 (RFC 3849).',
  ]);
});
