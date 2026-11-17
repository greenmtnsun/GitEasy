// =============================================================================
// Script  : pronoun.js
// Author  : Keith Ramsey
// Created : 2026-11-17
// =============================================================================
// Change Log
// -----------------------------------------------------------------------------
// 2026-11-17  Keith Ramsey  Initial creation. Node port of hooks/lib/pronoun-label-detect.ps1
//                            (created 2026-11-12) for the portable kit. Shared
//                            check for pronoun-label-guard. Finds a bare I, me,
//                            my, you or your in the text of an AskUserQuestion
//                            call, so a question never leaves Keith guessing
//                            whether "I" is him or the session. A pronoun counts
//                            as labelled when a parenthetical follows it
//                            ("I (Claude)", "you (Keith)") or when it sits inside
//                            one ("Keith (you)"). Once the first pronoun of a
//                            person in a field is labelled, later ones in that
//                            field may stay bare. Code spans, fenced code,
//                            double-quoted passages and quoted (">") lines are not
//                            checked, so quoted words and drafts to approve pass.
//                            The PowerShell patterns use inline (?i:...) groups,
//                            which Node's regex engine lacks, so me/my/mine/myself
//                            are spelled out per letter case and the second-person
//                            pattern carries the i flag. Curly apostrophes stay.
// =============================================================================
'use strict';

// I (with 'm 'll 've 'd) is case-sensitive; me, my, mine, myself match in any case.
const FIRST_PERSON = /(?<![\w'’/-])(?:I(?:['’](?:m|ll|ve|d))?(?![\w'’]|[/-]\w)|(?:[Mm][Ee]|[Mm][Yy]|[Mm][Ii][Nn][Ee]|[Mm][Yy][Ss][Ee][Ll][Ff])(?![\w'’-]))/;
const SECOND_PERSON = /(?<![\w'’/-])(?:you(?:['’](?:re|ll|ve|d))?|your|yours|yourself)(?![\w'’-])/i;

// Steps (removeUncheckedText):
//   1. Remove fenced code blocks.
//   2. Remove lines that start with ">" (quoted text, such as a draft to approve).
//   3. Remove inline code spans and double-quoted passages, straight or curly.
//   4. Return what is left.
function removeUncheckedText(text) {
  let t = text.replace(/```[\s\S]*?```/g, ' ');
  t = t.replace(/^[ \t]*>.*$/gm, ' ');
  t = t.replace(/`[^`\r\n]*`/g, ' ');
  t = t.replace(/"[^"\r\n]*"/g, ' ');
  t = t.replace(/“[^”\r\n]*”/g, ' ');
  return t;
}

// Steps (findBarePronoun):
//   1. Return null for empty text.
//   2. Blank out code, quoted passages and quoted lines.
//   3. For each person, find its first occurrence; skip the person if there is none.
//   4. Pass the person when a "(" follows the word or the word sits right after "(".
//   5. Return the first failing word (lowest index) with up to 40 characters of context on each side.
function findBarePronoun(text) {
  if (!text || !text.trim()) return null;
  const clean = removeUncheckedText(text);
  const failures = [];
  for (const pattern of [FIRST_PERSON, SECOND_PERSON]) {
    const m = pattern.exec(clean);
    if (!m) continue;
    const after = clean.slice(m.index + m[0].length);
    const before = clean.slice(0, m.index);
    if (/^\s*\(/.test(after) || /\(\s*$/.test(before)) continue;
    const start = Math.max(0, m.index - 40);
    const end = Math.min(clean.length, m.index + m[0].length + 40);
    failures.push({ word: m[0], index: m.index, context: clean.slice(start, end).replace(/\s+/g, ' ').trim() });
  }
  if (!failures.length) return null;
  failures.sort((a, b) => a.index - b.index);
  return failures[0];
}

// Steps (getQuestionPronounFindings):
//   1. Walk the questions in order, numbering them from 1; skip null entries.
//   2. Check the question text and header with findBarePronoun.
//   3. Check each option's label and description the same way. Previews are not checked: they hold mock-ups and code.
//   4. Return one finding per failing field: question number, field name, the word and its context.
function getQuestionPronounFindings(questions) {
  const findings = [];
  const list = Array.isArray(questions) ? questions : [questions];
  let n = 0;
  for (const q of list) {
    n++;
    if (q == null || typeof q !== 'object') continue;
    const str = (v) => (v == null ? '' : String(v));
    const fields = [['question text', str(q.question)], ['header', str(q.header)]];
    const options = Array.isArray(q.options) ? q.options : (q.options == null ? [] : [q.options]);
    for (const o of options) {
      if (o == null || typeof o !== 'object') continue;
      fields.push([`option label "${str(o.label)}"`, str(o.label)]);
      fields.push([`description of option "${str(o.label)}"`, str(o.description)]);
    }
    for (const [field, value] of fields) {
      const hit = findBarePronoun(value);
      if (hit) findings.push({ question: n, field, word: hit.word, context: hit.context });
    }
  }
  return findings;
}

module.exports = { FIRST_PERSON, SECOND_PERSON, removeUncheckedText, findBarePronoun, getQuestionPronounFindings };
