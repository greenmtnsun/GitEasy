// =============================================================================
// Script  : stray-codeblock-detect.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            stray-codeblock-detect.ps1 (2026-05-08) for the
//                            portable kit. PreToolUse on Edit, Write and
//                            MultiEdit inside the project dir: blocks saves
//                            where the target file name, with no extension,
//                            matches a Markdown code-block language tag
//                            case-sensitively (the 2026-05-04 Docs/powershell
//                            API-key leak signature). Capitalised real files
//                            (Dockerfile, Makefile, LICENSE, README) pass, as
//                            do dot-prefixed names (.gitignore) and anything
//                            under Tests\Fixtures. Payload drift is logged.
//                            Scope change from the PC original: "inside the
//                            project dir" replaces C:\Sysadmin\Scripts\ and
//                            C:\Users\keith\.claude\.
// =============================================================================
'use strict';
const path = require('path');
const C = require('./lib/common');
const S = require('./lib/file-scope');

const NAME = 'stray-codeblock-detect';
const IN_SCOPE_TOOLS = ['Edit', 'Write', 'MultiEdit'];

// Lowercase code-block tags. The comparison is case-sensitive, and Markdown tags are lowercase,
// so Dockerfile, Makefile, LICENSE, README, NOTICE, CHANGELOG, CONTRIBUTING, AUTHORS, COPYING, TODO pass.
const CODE_BLOCK_TAGS = [
  'powershell', 'ps', 'ps1', 'pwsh',
  'python', 'py', 'python3',
  'bash', 'sh', 'shell', 'zsh', 'fish', 'ksh',
  'javascript', 'js', 'jsx', 'mjs', 'cjs',
  'typescript', 'ts', 'tsx',
  'sql', 'mysql', 'postgres', 'postgresql', 'tsql', 'plsql',
  'yaml', 'yml',
  'json', 'jsonc', 'json5',
  'markdown', 'md', 'mdx',
  'html', 'htm',
  'css', 'scss', 'sass', 'less',
  'ruby', 'rb', 'erb',
  'go', 'golang',
  'rust', 'rs',
  'c', 'cpp', 'c++', 'csharp', 'cs', 'objective-c', 'objc',
  'java', 'kotlin', 'kt', 'scala', 'clj', 'clojure',
  'xml', 'xsl', 'xslt',
  'diff', 'patch',
  'dockerfile', 'docker', 'makefile', 'make', 'cmake',
  'toml', 'ini', 'cfg', 'conf',
  'env', 'dotenv',
  'nginx', 'apache', 'caddy', 'httpd',
  'terraform', 'tf', 'hcl',
  'regex', 'regexp',
  'text', 'plaintext', 'plain', 'txt',
  'console', 'output', 'log',
  'mermaid', 'plantuml',
  'graphql', 'gql',
  'protobuf', 'proto',
  'r', 'rscript',
  'matlab', 'octave',
  'lua', 'perl', 'pl', 'php',
  'swift', 'dart',
  'asm', 'assembly', 'nasm',
  'vbnet', 'vb', 'vba',
];

// Steps (matchTag):
//   1. Files with an extension always pass (the leak signature is extensionless name-as-tag).
//   2. Compare the bare file name against each tag case-sensitively; return the tag or null.
function matchTag(fileName) {
  if (path.extname(fileName) !== '') return null;
  return CODE_BLOCK_TAGS.find(tag => fileName === tag) || null;
}

// Steps (main):
//   1. Read the payload; fail open on bad JSON; step aside when the PowerShell twin exists.
//   2. Only Edit, Write and MultiEdit matter. Log drift and exit 0 when tool_input or file_path is missing.
//   3. Exit 0 outside the project dir or under Tests\Fixtures.
//   4. Exit 0 when the file name has an extension or matches no tag; else block with the leak explanation.
C.run(() => {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);
  if (!IN_SCOPE_TOOLS.includes(p.tool_name)) process.exit(0);
  if (!p.tool_input) { C.writeDrift(NAME, 'tool_input missing', p); process.exit(0); }
  if (!Object.prototype.hasOwnProperty.call(p.tool_input, 'file_path')) { C.writeDrift(NAME, 'tool_input.file_path missing', p); process.exit(0); }
  const filePath = p.tool_input.file_path;
  if (!filePath) process.exit(0);

  const scope = S.inProject(filePath, p);
  if (!scope) process.exit(0);
  if (S.isTestFixture(scope)) process.exit(0);

  const fileName = S.fileName(filePath);
  const matchedTag = matchTag(fileName);
  if (!matchedTag) process.exit(0);

  C.block([
    `Stray code-block hook: blocked save to ${filePath}`,
    '',
    `Filename '${fileName}' matches a Markdown code-block language tag.`,
    'This is the signature of a paste-error where a code-block opener like',
    '```' + matchedTag + ' became the literal filename. The 2026-05-04 plaintext-API-key',
    'leak landed exactly this way — Docs/powershell with an Anthropic key inside.',
    '',
    'If this file is legitimate:',
    '  - Give it a real extension (.ps1, .py, .sh, .md, etc.), OR',
    '  - Capitalize the name (Dockerfile, Makefile, LICENSE, README all pass), OR',
    "  - Place it under \\\\Tests\\\\Fixtures\\\\ if it's test data.",
  ]);
});
