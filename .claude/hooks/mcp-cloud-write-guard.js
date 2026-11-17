// =============================================================================
// Script  : mcp-cloud-write-guard.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/mcp-cloud-write-guard.ps1
//                            (created 2026-10-20) for the portable kit. PreToolUse
//                            hook for MCP connector tools on the Atlassian and
//                            Cloudflare servers. The shell and edit guards never
//                            see MCP calls, so this is the only fixed check on
//                            connector writes. Reads pass silently. Confluence
//                            writes are denied (live Confluence publishing is
//                            Keith's; memory feedback_confluence_publish_keith_only).
//                            Every other write, and any tool name it cannot place
//                            as a read, returns "ask" so Keith sees a prompt.
// Steps:
//   1. Read the hook payload from stdin. Bad or empty input exits 0 (fail open).
//      Step aside when the PowerShell twin exists.
//   2. Ignore anything that is not an mcp__<server>__<tool> call on an
//      Atlassian or Cloudflare server.
//   3. Split the tool name into lowercase words (camelCase, snake_case, kebab).
//   4. Classify: any write word means write; otherwise any read word means
//      read; otherwise unknown. Cloudflare set_active_* calls only pick the
//      account or worker for later calls, so they count as reads. A D1 query
//      runs SQL, which can change data, so it counts as a write.
//   5. Read: exit 0 with no output, so normal permission handling applies.
//   6. Confluence write on an Atlassian server: print permissionDecision deny.
//   7. Any other write, or unknown: print permissionDecision ask.
// =============================================================================
'use strict';
const C = require('./lib/common');

const NAME = 'mcp-cloud-write-guard';

const WRITE_WORDS = ['create', 'update', 'edit', 'delete', 'remove', 'add', 'put', 'post', 'patch',
  'publish', 'deploy', 'upload', 'write', 'move', 'rename', 'transition', 'execute',
  'run', 'purge', 'archive', 'restore', 'set', 'assign', 'invite', 'grant', 'revoke',
  'enable', 'disable', 'rollback', 'cancel', 'import', 'copy'];
const READ_WORDS = ['get', 'list', 'search', 'fetch', 'lookup', 'read', 'query', 'find', 'describe',
  'show', 'view', 'retrieve', 'info', 'whoami', 'keys', 'values', 'documentation', 'guide'];
const CONFLUENCE_WORDS = ['confluence', 'page', 'pages', 'blogpost', 'space', 'footer', 'inline'];

// Steps (splitWords):
//   1. Put a space between a lowercase letter or digit and the capital that follows it (getConfluencePage -> get Confluence Page).
//   2. Lower-case, split on anything that is not a letter or digit, drop empties.
function splitWords(name) {
  return name.replace(/([a-z0-9])([A-Z])/g, '$1 $2').toLowerCase().split(/[^a-z0-9]+/).filter(Boolean);
}

// Steps (main):
//   1. Payload, twin check; only mcp__<server>__<tool> on an Atlassian or Cloudflare server goes further.
//   2. Classify the words as read, write or unknown, with the Cloudflare set_active and d1 query exceptions.
//   3. A read exits 0 silently. A Confluence write prints deny; any other write or unknown prints ask.
function main() {
  const p = C.readPayload();
  if (!p) process.exit(0);
  if (C.hasPowerShellTwin(NAME)) process.exit(0);

  const tool = String(p.tool_name || '');
  const m = tool.match(/^mcp__(.+?)__(.+)$/);
  if (!m) process.exit(0);
  const server = m[1];
  const name = m[2];
  const isAtlassian = /atlassian/i.test(server);
  const isCloudflare = /cloudflare/i.test(server);
  if (!(isAtlassian || isCloudflare)) process.exit(0);

  const words = splitWords(name);
  let hasWrite = words.some(w => WRITE_WORDS.includes(w));
  let hasRead = words.some(w => READ_WORDS.includes(w));
  if (isCloudflare && words.includes('set') && words.includes('active')) { hasWrite = false; hasRead = true; }
  if (isCloudflare && words.includes('d1') && words.includes('query')) hasWrite = true;

  if (hasRead && !hasWrite) process.exit(0);

  const isConfluence = isAtlassian && words.some(w => CONFLUENCE_WORDS.includes(w));
  let decision;
  let reason;
  if (hasWrite && isConfluence) {
    decision = 'deny';
    reason = `Live Confluence writes are Keith's to make (feedback_confluence_publish_keith_only). Prepare the content or the command for him instead of calling ${tool}.`;
  } else if (hasWrite) {
    decision = 'ask';
    reason = `Cloud connector write: ${tool}. Keith approves each one.`;
  } else {
    decision = 'ask';
    reason = `mcp-cloud-write-guard cannot tell whether ${tool} reads or writes, so it asks.`;
  }
  C.emit({ hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: decision, permissionDecisionReason: reason } });
  process.exit(0);
}

C.run(main);
