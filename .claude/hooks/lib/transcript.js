// =============================================================================
// Script  : transcript.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of
//                            hooks/lib/gui-decision-detect.ps1 for the portable
//                            kit: the "does this reply wait on Keith" check and
//                            the transcript-tail reader shared by the Stop hooks
//                            (gui-decision-guard, no-stealth-completion-stop,
//                            pipeline-gate-stop). Keith: anything he needs to do
//                            or decide goes in the AskUserQuestion GUI, never in
//                            prose. Patterns and semantics match the PowerShell
//                            original line for line.
// =============================================================================
'use strict';
const fs = require('fs');

const MB = 1024 * 1024;

const OfferPattern = /\b(want me to|do you want me to|would you like me to|should i|shall i|which (one|of these|of those|would you|do you))\b/i;

// Phrases that leave Keith holding something: a wait, a pending call, a manual step to report.
const WaitPatterns = [
  /\b(waiting|wait) (on|for) (you|your|keith)\b/i,
  /\bblocked on (you|your|keith)\b/i,
  /\b(awaiting|pending) (your|keith)/i,
  /\bup to you\b/i,
  /\byour call\b/i,
  /\b(still )?needs? (you|your|keith)\b/i,
  /\bsay the word\b/i,
  /\bjust say\b/i,
  /\bgive me (the|a) (go|word|ok|nod)\b/i,
  /\b(once|when|after) you('ve| have| are|'re)? (confirm|decide|approve|reply|answer|pick|choose|ready|done|finished)\b/i,
  /\b(tell me|let me know)\b/i,
];

// The blessed lightweight form after Claude has already acted: "let me know if you'd rather Z".
const LightweightPattern = /\bif you('d| would) (rather|prefer)\b/i;

// A negation shortly before the phrase means the line says nothing is waiting.
const NegationPattern = /(\b(nothing|no one|not|never|none|without|no longer|no)\b|n't\b)/i;

// A conditional or a cited past call is not a wait: "if anything needs you", "resolved by your call".
const NotAWaitPattern = /\bif (anything|something|any|there)\b|\b(by|per|following|under) your (call|decision|ruling)\b|\byour call (is|was) (the )?(right|correct|good|sound)\b/i;

// Quoted spans are someone else's words: "...", curly double quotes, and 'single' quotes that are not apostrophes.
const QuotedPattern = /"[^"]*"|“[^”]*”|(?<!\w)'[^']*'(?!\w)/g;

// Steps (getInlineAskLine):
//   1. Drop what is not Claude speaking to Keith: fenced code blocks, quoted lines,
//      headings, table rows and HTML comments.
//   2. Strip bold, italic and inline-code marks so the patterns see plain words, and
//      replace quoted spans ("tell me when it ships") with a placeholder.
//   3. Return the first line that asks a question with an offer phrase ("want me to...?").
//   4. Return the first line that names a wait on Keith ("waiting on your call", "say the
//      word", "tell me which"), unless a negation sits just before the phrase ("nothing is
//      waiting on you"), the line is conditional or cites a past call ("if anything needs
//      you", "resolved by your call"), or it is the lightweight "let me know if you'd
//      rather" form.
//   5. Return the last line if it ends with a question mark.
function getInlineAskLine(text) {
  if (typeof text !== 'string' || !text.trim()) return null;
  const body = text.replace(/<!--.*?-->/gs, '');
  const kept = [];
  let inFence = false;
  for (const raw of body.split(/\r?\n/)) {
    if (/^\s*(```|~~~)/.test(raw)) { inFence = !inFence; continue; }
    if (inFence) continue;
    if (/^\s*(>|#{1,6}\s|\|)/.test(raw)) continue;
    const plain = raw.replace(/`[^`]*`/g, 'CODE').replace(/[*_]{1,3}/g, '').replace(QuotedPattern, 'QUOTE').trim();
    if (plain) kept.push(plain);
  }
  if (kept.length === 0) return null;

  for (const line of kept) {
    if (line.includes('?') && OfferPattern.test(line)) return line;
  }
  for (const line of kept) {
    for (const p of WaitPatterns) {
      const m = p.exec(line);
      if (!m) continue;
      let before = line.substring(Math.max(0, m.index - 25), m.index);
      const clauses = before.split(/[.;:!?,]/);
      before = clauses[clauses.length - 1];   // a negation in an earlier clause does not count
      if (NegationPattern.test(before)) continue;
      if (LightweightPattern.test(line) || NotAWaitPattern.test(line)) continue;
      return line;
    }
  }
  const last = kept[kept.length - 1];
  if (/\?["')\]]*$/.test(last)) return last;
  return null;
}

const InjectedPattern = /^\s*(<(task-notification|system-reminder|command-|local-command)|Stop hook feedback|This session is being continued)/;

// Steps (isGenuineUser):
//   1. Only user entries count; tool results, meta entries and summaries do not.
//   2. Text that the harness injects (task notifications, system reminders, slash-command
//      wrappers, stop-hook feedback, session-continuation summaries) does not count.
//   3. Any other plain text does.
function isGenuineUser(entry) {
  if (!entry || entry.type !== 'user' || !entry.message || entry.isMeta || entry.isCompactSummary) return false;
  const content = entry.message.content;
  if (typeof content === 'string') return !InjectedPattern.test(content);
  const items = content == null ? [] : (Array.isArray(content) ? content : [content]);
  for (const item of items) {
    if (item && item.type === 'text' && item.text && !InjectedPattern.test(item.text)) return true;
  }
  return false;
}

// Steps (parseLine):
//   1. Parse one transcript line as JSON; null when it is not JSON.
function parseLine(l) {
  try { return JSON.parse(l); } catch { return null; }
}

// Steps (getCurrentTurn):
//   1. Read the last 1 MB of the file, doubling up to 32 MB until the last message Keith
//      typed is in range. The live session holds the file open; a plain read handles that.
//   2. Walk the lines from the end back to that message, skipping bookkeeping records
//      (request copies, titles, snapshots) without parsing them.
//   3. Report whether an assistant message in that span called AskUserQuestion, the
//      text of the last assistant reply in it, and how many times this guard already
//      blocked in it (its "Stop hook feedback" entries).
function getCurrentTurn(transcriptPath) {
  const fd = fs.openSync(transcriptPath, 'r');
  try {
    const size = fs.fstatSync(fd).size;
    let want = 1 * MB;
    for (;;) {
      const take = Math.min(size, want);
      const buf = Buffer.alloc(take);
      let read = 0;
      while (read < take) {
        const n = fs.readSync(fd, buf, read, take - read, size - take + read);
        if (n <= 0) break;
        read += n;
      }
      const lines = buf.toString('utf8', 0, read).split('\n');
      const first = take < size ? 1 : 0;   // a cut-off first line is not JSON

      let ask = false, lastText = null, found = false, blocks = 0;
      for (let i = lines.length - 1; i >= first; i--) {
        const l = lines[i];
        if (l.length < 2 || /^\{"type":"(?!user"|assistant")/.test(l)) continue;
        if (l.includes('"role":"assistant"')) {
          if (!(l.includes('"name":"AskUserQuestion"') || (lastText === null && l.includes('"text"')))) continue;
          const o = parseLine(l);
          if (!o || o.type !== 'assistant' || o.isSidechain) continue;
          const content = o.message && o.message.content;
          const items = content == null ? [] : (Array.isArray(content) ? content : [content]);
          for (const item of items) {
            if (item && item.type === 'tool_use' && item.name === 'AskUserQuestion') ask = true;
          }
          if (lastText === null) {
            const texts = items.filter(it => it && it.type === 'text' && it.text);
            if (texts.length) lastText = texts[texts.length - 1].text;
          }
          continue;
        }
        if (l.includes('"type":"user"') && !l.includes('"tool_result"')) {
          if (l.includes('"isMeta":true') && l.includes('Stop hook feedback') && l.includes('GUI-decision guard:')) { blocks++; continue; }
          const o = parseLine(l);
          if (o && isGenuineUser(o)) { found = true; break; }
        }
      }
      if (found || take >= size || want >= 32 * MB) {
        return { askUsed: ask, lastText, foundTurnStart: found, guardBlocks: blocks };
      }
      want *= 2;
    }
  } finally { try { fs.closeSync(fd); } catch { } }
}

module.exports = { getInlineAskLine, isGenuineUser, getCurrentTurn };
