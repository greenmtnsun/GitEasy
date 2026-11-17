// =============================================================================
// Script  : file-scope.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Path-scope helpers shared by the
//                            PowerShell authoring guards in the kit. The PC
//                            originals fire only under C:\Sysadmin\Scripts\;
//                            in the kit a file is in scope when it resolves
//                            inside the project dir (CLAUDE_PROJECT_DIR, else
//                            the payload cwd). Relative paths resolve against
//                            that dir; either slash is accepted; folder tests
//                            (Public, Private, Tests\Fixtures) read path
//                            segments, not substrings, so a repo folder named
//                            PublicApi does not count as Public.
// =============================================================================
'use strict';
const path = require('path');
const C = require('./common');

// Steps (isAbsoluteLike):
//   1. True for a native absolute path, a Windows drive path (C:\ or C:/) or a UNC path (\\host).
//   2. Lets a Windows path on Linux be treated as absolute (and so outside the project), not as relative.
function isAbsoluteLike(fp) {
  return path.isAbsolute(fp) || /^[A-Za-z]:[\\/]/.test(fp) || /^[\\/]{2}/.test(fp);
}

// Steps (resolvePath):
//   1. Normalise backslashes to forward slashes on non-Windows hosts so a relative Public\X.ps1 resolves.
//   2. Absolute-like paths stay as given; relative ones resolve against the project dir.
function resolvePath(fp, payload) {
  const text = process.platform === 'win32' ? fp : fp.replace(/\\/g, '/');
  if (isAbsoluteLike(text)) return path.resolve(text);
  return path.resolve(C.projectDir(payload), text);
}

// Steps (inProject):
//   1. Resolve the file path (relative paths against the project dir).
//   2. A Windows-style absolute path on a non-Windows host can never be inside the project: return null.
//   3. Compute the path relative to the project dir; outside it (starts with ..) returns null.
//   4. Return { abs, rel, segments } where segments split the relative path on the separator.
function inProject(fp, payload) {
  if (typeof fp !== 'string' || !fp) return null;
  const root = path.resolve(C.projectDir(payload));
  const text = process.platform === 'win32' ? fp : fp.replace(/\\/g, '/');
  if (isAbsoluteLike(text) && !path.isAbsolute(text)) return null;
  const abs = resolvePath(fp, payload);
  const rel = path.relative(root, abs);
  if (!rel || rel.startsWith('..') || path.isAbsolute(rel)) return null;
  const segments = rel.split(path.sep).filter(Boolean);
  return { abs, rel: segments.join('/'), segments };
}

// Steps (hasFolder):
//   1. True when any directory segment (not the file name) equals `name`, ignoring case.
function hasFolder(scope, name) {
  const want = name.toLowerCase();
  return scope.segments.slice(0, -1).some(s => s.toLowerCase() === want);
}

// Steps (isTestFixture):
//   1. True when consecutive directory segments read Tests then Fixtures, ignoring case (the \Tests\Fixtures\ exemption).
function isTestFixture(scope) {
  const dirs = scope.segments.slice(0, -1).map(s => s.toLowerCase());
  return dirs.some((s, i) => s === 'tests' && dirs[i + 1] === 'fixtures');
}

// Steps (fileName):
//   1. The last segment of the path, with either slash as separator.
function fileName(fp) {
  const parts = String(fp).split(/[\\/]/);
  return parts[parts.length - 1];
}

module.exports = { isAbsoluteLike, resolvePath, inProject, hasFolder, isTestFixture, fileName };
