// =============================================================================
// Script  : approved-verbs.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. The approved PowerShell verb list
//                            for phantom-verb-killer.js, which cannot call
//                            Get-Verb from Node. Source: (Get-Verb).Verb on
//                            PowerShell 7.4.6, captured 2026-11-17 (100 verbs,
//                            in Get-Verb's own order). Refresh by re-running
//                            Get-Verb when a PowerShell release adds a verb.
// =============================================================================
'use strict';

module.exports = [
  'Add', 'Clear', 'Close', 'Copy', 'Enter', 'Exit', 'Find', 'Format', 'Get', 'Hide', 'Join', 'Lock',
  'Move', 'New', 'Open', 'Optimize', 'Push', 'Pop', 'Redo', 'Remove', 'Rename', 'Reset', 'Resize',
  'Search', 'Select', 'Set', 'Show', 'Skip', 'Split', 'Step', 'Switch', 'Undo', 'Unlock', 'Watch',
  'Connect', 'Disconnect', 'Read', 'Receive', 'Send', 'Write',
  'Backup', 'Checkpoint', 'Compare', 'Compress', 'Convert', 'ConvertFrom', 'ConvertTo', 'Dismount',
  'Edit', 'Expand', 'Export', 'Group', 'Import', 'Initialize', 'Limit', 'Merge', 'Mount', 'Out',
  'Publish', 'Restore', 'Save', 'Sync', 'Unpublish', 'Update',
  'Debug', 'Measure', 'Ping', 'Repair', 'Resolve', 'Test', 'Trace',
  'Approve', 'Assert', 'Build', 'Complete', 'Confirm', 'Deny', 'Deploy', 'Disable', 'Enable',
  'Install', 'Invoke', 'Register', 'Request', 'Restart', 'Resume', 'Start', 'Stop', 'Submit',
  'Suspend', 'Uninstall', 'Unregister', 'Wait', 'Use',
  'Block', 'Grant', 'Protect', 'Revoke', 'Unblock', 'Unprotect',
];
