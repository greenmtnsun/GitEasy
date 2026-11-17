// Regression check for the review loops in workflows\delivery-pipeline.js (review-loops spec 1.2.2).
// Runs the real script body with scripted agent() replies: clean, repair, waiver, cross re-run,
// every stop rule, the pass cap, the UI branch, low findings carried at the cap, Keith's rulings on
// resume, the stop record (findings, open items, the tree at start), and the small-item loop
// (size check, one code-and-security reviewer, the 3-round cap). Re-run after any edit to the script or the spec.
// Usage: node C:\Users\keith\.claude\skills\delivery-pipeline\tests\run-scenarios.js C:\Users\keith\.claude\workflows\delivery-pipeline.js
// Expect: "25/25 passed", exit 0.
const fs = require('fs')
const assert = require('assert')

const src = fs.readFileSync(process.argv[2], 'utf8').replace(/^export const meta/m, 'const meta')
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor
const run = new AsyncFunction('agent', 'log', 'phase', 'args', src)

const F = (id, severity, state = 'open', extra = {}) =>
  ({ id, severity, where: 'x.ps1:1', evidence: 'seen', suggestedRepair: 'fix', state, needsKeith: false, ...extra })

const base = {
  discovery: { goalRecordWritten: true, goalRecordPath: 'g.md', stackConfirmed: 'PowerShell', cloudTargetConfirmed: 'Azure', hasUi: false, treeAtStart: [], notes: [] },
  design: { drWritten: false, umlWritten: false, mockupPaths: ['m1.png'], notes: [] },
  build: { filesChanged: ['a.ps1'], airGapClean: true, provenanceStamped: true, notes: [] },
  // Not a small item unless a scenario says so, so S1 to S17 run the separate code and security loops.
  'verify-size': { lines: 500, notes: [] },
  verify: { staticAnalysisRun: true, staticAnalysisClean: true, unitTestsRun: true, unitTestsPassed: 10, unitTestsTotal: 10, integrationTestsRun: true, visualUiTested: true, screenshotPaths: ['s1.png'], adversarialUiTested: false, performanceChecked: false, accessibilityChecked: false, notes: [] },
  document: { wikiUpdated: false, umlResynced: false, blogDrafted: false, changelogUpdated: false, waiversLogged: true, carriedLogged: true, notes: [] },
  'ship-dev': { devDeployed: false, devEndpointVerified: false, notes: [] },
  operate: { telemetryWired: false, rollbackPlanWritten: false, retroScheduled: false, notes: [] },
}

async function scenario(opts) {
  // Steps:
  // 1. Build a fake agent() that records each call by label and occurrence (code-review-r1#2).
  // 2. Answer from the scenario's respond() first, then the phase defaults, then clean review defaults.
  // 3. Run the real script body with that agent and the scenario's args.
  // 4. Return the script's result, the call list and every prompt, for the assertions.
  const calls = []
  const prompts = {}
  const seen = {}
  const agent = async (prompt, o) => {
    seen[o.label] = (seen[o.label] || 0) + 1
    const key = `${o.label}#${seen[o.label]}`
    calls.push(key)
    prompts[key] = prompt
    if (opts.respond) {
      const r = opts.respond(key, prompt)
      if (r !== undefined) return r
    }
    if (base[o.label]) return { ...base[o.label], ...((opts.overrides || {})[o.label] || {}) }
    if (/-review-r/.test(o.label)) return { findings: [], notes: [] }
    if (/-repair-r/.test(o.label)) return { repairs: [], filesChanged: [], notes: [] }
    if (/-rerun-r/.test(o.label)) return { staticAnalysisClean: true, testsPassed: 10, testsTotal: 10, notes: [] }
    throw new Error('unscripted agent call ' + key)
  }
  const out = await run(agent, () => {}, () => {}, { project: 'demo', description: 'demo project', stack: 'PowerShell', ...(opts.args || {}) })
  return { out, calls, prompts }
}

const repaired = (id, files) => ({ repairs: [{ id, action: 'repaired', detail: 'changed it' }], filesChanged: files, notes: [] })
const repairedThrough = n => Array.from({ length: n }, (_, i) => F(`code-${i + 1}`, 'medium', 'repaired'))
// Code review finds one new finding of the given severity every round; each repair fixes it.
const everyRound = severity => k => {
  const m = /^code-review-r(\d)#1$/.exec(k)
  if (m) {
    const n = Number(m[1])
    return { findings: [...Array.from({ length: n - 1 }, (_, i) => F(`code-${i + 1}`, severity, 'repaired')), F(`code-${n}`, severity)], notes: [] }
  }
  const r = /^code-repair-r(\d)#1$/.exec(k)
  if (r) return repaired(`code-${r[1]}`, ['a.ps1'])
  return undefined
}

// The same, for any review id (code-security-review-r1#1 and so on).
const everyRoundIn = (review, severity) => k => {
  const m = new RegExp(`^${review}-review-r(\\d)#1$`).exec(k)
  if (m) {
    const n = Number(m[1])
    return { findings: [...Array.from({ length: n - 1 }, (_, i) => F(`${review}-${i + 1}`, severity, 'repaired')), F(`${review}-${n}`, severity)], notes: [] }
  }
  const r = new RegExp(`^${review}-repair-r(\\d)#1$`).exec(k)
  if (r) return repaired(`${review}-${r[1]}`, ['a.ps1'])
  return undefined
}
const small = { 'verify-size': { lines: 40 } }

const tests = {
  'S1 no UI, everything clean': async () => {
    const { out, calls, prompts } = await scenario({})
    assert.strictEqual(out.halted, undefined)
    assert.ok(calls.includes('code-review-r1#1') && calls.includes('security-review-r1#1'))
    assert.ok(!calls.some(c => c.startsWith('ui')))
    assert.strictEqual(out.reviews.verify.status, 'clean')
    assert.deepStrictEqual(out.waivers, [])
    assert.deepStrictEqual(out.carried, [])
    assert.deepStrictEqual(out.openForKeith, [])
    assert.deepStrictEqual(out.treeAtStart, [])
    assert.ok(!/already uncommitted/.test(prompts['build#1']), 'clean tree: Build prompt names no paths')
    assert.ok(/git show origin\/HEAD:REVIEW\.md/.test(prompts['code-review-r1#1']), 'reviewer is told to read REVIEW.md from the default branch (spec 1.2.2)')
    assert.ok(/git show origin\/HEAD:REVIEW\.md/.test(prompts['security-review-r1#1']), 'security reviewer gets the same REVIEW.md instruction')
  },
  'S2 repair, waiver accepted, cross re-run on changed files': async () => {
    const { out, calls, prompts } = await scenario({
      respond: k => ({
        'code-review-r1#1': { findings: [F('code-1', 'medium')], notes: [] },
        'code-repair-r1#1': repaired('code-1', ['a.ps1']),
        'code-review-r2#1': { findings: [F('code-1', 'medium', 'repaired')], notes: [] },
        'security-review-r1#1': { findings: [F('security-1', 'low')], notes: [] },
        'security-repair-r1#1': { repairs: [{ id: 'security-1', action: 'waiver-proposed', waiverReason: 'matches the file style', detail: 'kept' }], filesChanged: ['b.ps1'], notes: [] },
        'security-review-r2#1': { findings: [F('security-1', 'low', 'waived', { waiverReason: 'matches the file style' })], notes: [] },
      })[k],
    })
    assert.strictEqual(out.halted, undefined)
    assert.ok(calls.includes('code-rerun-r1#1'), 'code re-run after repair')
    assert.ok(calls.includes('code-review-r1#2'), 'code review ran again in pass 2')
    assert.ok(/Only these files[^\n]*b\.ps1/.test(prompts['code-review-r1#2']), 'pass-2 code review scoped to b.ps1')
    assert.ok(/of the form code-<n>\./.test(prompts['code-review-r1#1']), 'pass-1 ids unchanged')
    assert.ok(/of the form code-p2-<n>\./.test(prompts['code-review-r1#2']), 'pass-2 ids carry the pass')
    assert.ok(!calls.includes('security-review-r1#2'), 'security not re-run: pass-2 code review changed nothing')
    assert.strictEqual(out.waivers.length, 1)
    assert.strictEqual(out.waivers[0].id, 'security-1')
    assert.ok(/security-1/.test(prompts['document#1']), 'Document agent gets the waiver')
    assert.ok(/into the repo's Docs\/PIPELINE\.md,/.test(prompts['document#1']), 'no ledgerPath: default ledger named')
  },
  'S3 same finding open after 2 repair rounds stops (section 18)': async () => {
    const { out, calls } = await scenario({
      respond: k => (/^code-review-r[123]#1$/.test(k) ? { findings: [F('code-1', 'medium')], notes: [] }
        : /^code-repair-r\d#1$/.test(k) ? repaired('code-1', ['a.ps1']) : undefined),
    })
    assert.strictEqual(out.halted, true)
    assert.strictEqual(out.haltedAt, 'Verify')
    assert.ok(/still open after 2 repair rounds: code-1/.test(out.stopReason), out.stopReason)
    assert.ok(calls.includes('code-review-r3#1') && !calls.includes('code-repair-r3#1'))
    assert.ok(!calls.includes('security-review-r1#1') && !calls.includes('document#1'))
  },
  'S4 waiver proposed for a high finding goes to Keith': async () => {
    const { out } = await scenario({
      respond: k => ({
        'code-review-r1#1': { findings: [F('code-1', 'high')], notes: [] },
        'code-repair-r1#1': { repairs: [{ id: 'code-1', action: 'waiver-proposed', waiverReason: 'too hard', detail: 'no' }], filesChanged: [], notes: [] },
      })[k],
    })
    assert.strictEqual(out.halted, true)
    assert.ok(/goes to Keith: code-1/.test(out.stopReason), out.stopReason)
  },
  'S5 needsKeith stops before any repair': async () => {
    const { out, calls } = await scenario({
      respond: k => (k === 'code-review-r1#1' ? { findings: [F('code-1', 'medium', 'open', { needsKeith: true })], notes: [] } : undefined),
    })
    assert.strictEqual(out.halted, true)
    assert.ok(/needs Keith/.test(out.stopReason))
    assert.ok(!calls.includes('code-repair-r1#1'))
    assert.strictEqual(out.findingsForKeith.length, 1)
    for (const t of ['code-1 [medium] at x.ps1:1', 'Evidence: seen', 'Suggested repair: fix', 'keithRulings']) assert.ok(out.askKeith.includes(t), 'askKeith has: ' + t)
  },
  'S6 a new medium finding every round stops at round 5': async () => {
    const { out, calls } = await scenario({
      respond: k => {
        const m = /^code-review-r(\d)#1$/.exec(k)
        if (m) {
          const n = Number(m[1])
          const prior = Array.from({ length: n - 1 }, (_, i) => F(`code-${i + 1}`, 'low', 'repaired'))
          return { findings: [...prior, F(`code-${n}`, 'medium')], notes: [] }
        }
        const r = /^code-repair-r(\d)#1$/.exec(k)
        if (r) return repaired(`code-${r[1]}`, ['a.ps1'])
        return undefined
      },
    })
    assert.strictEqual(out.halted, true)
    assert.ok(/still open at round 5: code-5/.test(out.stopReason), out.stopReason)
    assert.ok(calls.includes('code-review-r5#1') && !calls.includes('code-repair-r5#1'))
    assert.ok(!out.askKeith.includes('not re-tested or reviewed'), 'a stop at the cap is not an unreviewed repair round')
  },
  'S7 UI design escalation halts before Build': async () => {
    const { out, calls } = await scenario({
      overrides: { discovery: { hasUi: true }, design: { openForKeith: ['Pick the button wording'] } },
      respond: k => ({
        'ui-design-review-r1#1': { findings: [F('ui-design-1', 'critical')], notes: [] },
        'ui-design-repair-r1#1': { repairs: [{ id: 'ui-design-1', action: 'escalate', detail: 'brand rules missing' }], filesChanged: [], notes: [] },
      })[k],
    })
    assert.strictEqual(out.halted, true)
    assert.strictEqual(out.haltedAt, 'Design')
    assert.ok(!calls.includes('build#1'))
    assert.ok(!calls.some(c => c.startsWith('ui-design-rerun')), 'Design review has no test re-run')
    assert.deepStrictEqual(out.openForKeith, ['design: Pick the button wording'])
    assert.ok(out.askKeith.includes('design: Pick the button wording'), 'askKeith lists the open item')
    assert.ok(out.askKeith.includes('Builder: escalate, brand rules missing'), 'askKeith shows the escalation')
    assert.ok(out.askKeith.includes("The stopping round's repairs were not re-tested or reviewed. A resume with Keith's ruling reruns that repair round."), 'askKeith says the stopped round is unreviewed (spec 1.2.1)')
  },
  'S8 UI project runs all four reviews': async () => {
    const { out, calls, prompts } = await scenario({ overrides: { discovery: { hasUi: true } } })
    assert.strictEqual(out.halted, undefined)
    for (const c of ['ui-design-review-r1#1', 'code-review-r1#1', 'security-review-r1#1', 'ui-review-r1#1']) assert.ok(calls.includes(c), c)
    assert.ok(/s1\.png/.test(prompts['ui-review-r1#1']) && /m1\.png/.test(prompts['ui-review-r1#1']), 'UI review sees screenshots and mockups')
    assert.ok(out.reviews.design && out.reviews.verify)
  },
  'S9 reviewer returning nothing stops': async () => {
    const { out } = await scenario({ respond: k => (k === 'security-review-r1#1' ? null : undefined) })
    assert.strictEqual(out.halted, true)
    assert.ok(/returned nothing/.test(out.stopReason))
  },
  'S10 reviews that keep changing files hit the pass cap': async () => {
    const { out } = await scenario({
      respond: k => {
        const m = /^(code|security)-review-r(\d)#(\d+)$/.exec(k)
        if (m) return m[2] === '1' ? { findings: [F(`${m[1]}-${m[3]}`, 'low')], notes: [] } : { findings: [F(`${m[1]}-${m[3]}`, 'low', 'repaired')], notes: [] }
        const r = /^(code|security)-repair-r1#(\d+)$/.exec(k)
        if (r) return repaired(`${r[1]}-${r[2]}`, [`${r[1]}.ps1`])
        return undefined
      },
    })
    assert.strictEqual(out.halted, true)
    assert.ok(/did not settle within 5 passes/.test(out.stopReason), out.stopReason)
  },
  'S11 ledgerPath sends waivers to the named ledger and leaves earlier prompts alone': async () => {
    const ledgerPath = 'C:\\repo\\ProductB\\Docs\\PIPELINE.md'
    const { out, prompts } = await scenario({ args: { ledgerPath } })
    assert.strictEqual(out.halted, undefined)
    assert.ok(prompts['document#1'].includes(`into ${ledgerPath},`), 'Document agent names the given ledger')
    assert.ok(!/the repo's Docs\/PIPELINE\.md/.test(prompts['document#1']), 'default ledger not named')
    for (const k of ['discovery#1', 'design#1', 'build#1', 'verify#1', 'code-review-r1#1']) {
      assert.ok(!prompts[k].includes('ProductB'), `${k} prompt unchanged, so a resumed run keeps its cache`)
    }
  },
  'S12 only low findings open at the cap are carried and the run goes on': async () => {
    const { out, calls, prompts } = await scenario({ respond: everyRound('low') })
    assert.strictEqual(out.halted, undefined)
    assert.strictEqual(out.reviews.verify.results.code[0].status, 'carried')
    assert.ok(!calls.includes('code-repair-r5#1'), 'no repair at the cap')
    assert.ok(calls.includes('security-review-r1#1'), 'the phase went on')
    assert.deepStrictEqual(out.carried.map(c => c.review + '/' + c.id), ['code/code-5'])
    assert.ok(/6\. Write every carried finding[\s\S]*code-5/.test(prompts['document#1']), 'Document agent gets the carried finding')
  },
  'S13 a Keith ruling at the cap: one repair carries it out, one more review, then on': async () => {
    const keithRulings = [{ id: 'code-5', ruling: 'Use the plain wording' }]
    const withRuling = await scenario({ args: { keithRulings }, respond: k => k === 'code-review-r6#1' ? { findings: repairedThrough(5), notes: [] } : everyRound('medium')(k) })
    const without = await scenario({ respond: everyRound('medium') })
    assert.strictEqual(withRuling.out.halted, undefined)
    assert.ok(withRuling.calls.includes('code-repair-r5#1') && withRuling.calls.includes('code-review-r6#1'))
    assert.ok(withRuling.prompts['code-repair-r5#1'].includes('Use the plain wording'), 'repair r5 carries the ruling')
    for (const k of without.calls.filter(c => c.startsWith('code-'))) {
      assert.strictEqual(withRuling.prompts[k], without.prompts[k], k + ' prompt unchanged, so a resumed run replays it from cache')
    }
  },
  'S14 the review after a ruling finds a new medium finding: stop again': async () => {
    const { out } = await scenario({
      args: { keithRulings: [{ id: 'code-5', ruling: 'Use the plain wording' }] },
      respond: k => k === 'code-review-r6#1' ? { findings: [...repairedThrough(5), F('code-6', 'medium')], notes: [] } : everyRound('medium')(k),
    })
    assert.strictEqual(out.halted, true)
    assert.ok(/still open at round 6: code-6/.test(out.stopReason), out.stopReason)
  },
  'S15 a needsKeith finding Keith ruled on is repaired, not stopped': async () => {
    const { out, prompts } = await scenario({
      args: { keithRulings: [{ id: 'code-1', ruling: 'The diagram is right; change the code' }] },
      respond: k => ({
        'code-review-r1#1': { findings: [F('code-1', 'medium', 'open', { needsKeith: true })], notes: [] },
        'code-repair-r1#1': repaired('code-1', ['a.ps1']),
        'code-review-r2#1': { findings: [F('code-1', 'medium', 'repaired', { needsKeith: true })], notes: [] },
      })[k],
    })
    assert.strictEqual(out.halted, undefined)
    assert.ok(prompts['code-repair-r1#1'].includes('The diagram is right; change the code'))
  },
  'S16 Keith rules a high finding waived: one repair round, then it closes': async () => {
    const { out, calls } = await scenario({
      args: { keithRulings: [{ id: 'code-1', ruling: 'Waive it: accepted risk for this release' }] },
      respond: k => ({
        'code-review-r1#1': { findings: [F('code-1', 'high')], notes: [] },
        'code-repair-r1#1': { repairs: [{ id: 'code-1', action: 'waiver-proposed', waiverReason: 'Keith ruled: accepted risk', detail: 'kept' }], filesChanged: [], notes: [] },
        'code-review-r2#1': { findings: [F('code-1', 'high', 'waived', { waiverReason: 'Keith ruled: accepted risk' })], notes: [] },
      })[k],
    })
    assert.strictEqual(out.halted, undefined)
    assert.ok(!calls.includes('code-repair-r2#1'), 'the carried-out ruling closes the waived high finding')
    assert.deepStrictEqual(out.waivers.map(w => w.id), ['code-1'])
  },
  'S17 paths uncommitted at start reach Build and the summary': async () => {
    const { out, prompts } = await scenario({ overrides: { discovery: { treeAtStart: ['logs/run.log'] } } })
    assert.ok(/already uncommitted[\s\S]*logs\/run\.log/.test(prompts['build#1']), 'Build is told to leave it alone')
    assert.deepStrictEqual(out.treeAtStart, ['logs/run.log'])
  },
  'S18 small item: one code-and-security reviewer per round, cap 3': async () => {
    const { out, calls, prompts } = await scenario({ overrides: small })
    assert.strictEqual(out.halted, undefined)
    assert.ok(/File: a\.ps1/.test(prompts['verify-size#1']), 'the size agent counts the one source file')
    assert.ok(calls.includes('code-security-review-r1#1'))
    assert.ok(!calls.some(c => /^(code|security)-review-/.test(c)), 'no separate code or security loop')
    for (const t of ['Correctness bugs', 'Steps: blueprint', 'Injection classes', 'Secrets and credential handling']) assert.ok(prompts['code-security-review-r1#1'].includes(t), 'one reviewer gets both checklists: ' + t)
    assert.deepStrictEqual(out.verifySize, { small: true, file: 'a.ps1', lines: 40, maxRounds: 3 })
    assert.strictEqual(out.reviews.verify.status, 'clean')
  },
  'S19 small item: only low findings open at round 3 are carried': async () => {
    const { out, calls } = await scenario({ overrides: small, respond: everyRoundIn('code-security', 'low') })
    assert.strictEqual(out.halted, undefined)
    assert.ok(calls.includes('code-security-review-r3#1') && !calls.includes('code-security-review-r4#1') && !calls.includes('code-security-repair-r3#1'))
    const loop = out.reviews.verify.results['code-security'][0]
    assert.strictEqual(loop.status, 'carried')
    assert.strictEqual(loop.rounds, 3)
    assert.deepStrictEqual(out.carried.map(c => c.id), ['code-security-3'])
  },
  'S20 small item: a medium finding open at round 3 stops': async () => {
    const { out, calls } = await scenario({ overrides: small, respond: everyRoundIn('code-security', 'medium') })
    assert.strictEqual(out.halted, true)
    assert.ok(/findings still open at round 3: code-security-3/.test(out.stopReason), out.stopReason)
    assert.ok(!calls.includes('code-security-review-r4#1'))
  },
  'S21 two source files: no size check, separate loops, cap 5': async () => {
    const { out, calls } = await scenario({ overrides: { build: { filesChanged: ['a.ps1', 'b.ps1'] } } })
    assert.ok(!calls.some(c => c.startsWith('verify-size')), 'no size agent for more than one source file')
    assert.ok(calls.includes('code-review-r1#1') && calls.includes('security-review-r1#1'))
    assert.deepStrictEqual(out.verifySize, { small: false, file: null, lines: null, maxRounds: 5 })
  },
  'S22 test files are not counted toward the size': async () => {
    const { out, prompts } = await scenario({ overrides: { ...small, build: { filesChanged: ['src/a.ps1', 'src/a.Tests.ps1', 'tests/helper.ps1', 'web/app.test.js'] } } })
    assert.ok(/File: src\/a\.ps1/.test(prompts['verify-size#1']), prompts['verify-size#1'])
    assert.strictEqual(out.verifySize.small, true)
  },
  'S23 a failed line count runs the full loops': async () => {
    const { out, calls } = await scenario({ overrides: { 'verify-size': { lines: -1 } } })
    assert.ok(calls.includes('code-review-r1#1') && calls.includes('security-review-r1#1'))
    assert.deepStrictEqual(out.verifySize, { small: false, file: 'a.ps1', lines: null, maxRounds: 5 })
  },
  'S24 a file of exactly 200 lines is not a small item': async () => {
    const { out, calls } = await scenario({ overrides: { 'verify-size': { lines: 200 } } })
    assert.strictEqual(out.verifySize.small, false)
    assert.ok(calls.includes('code-review-r1#1'))
  },
  'S25 a ruling on a finding stopped by the 2-repair rule lands on its first repair, then normal rules': async () => {
    const stuck = k => (/^code-review-r\d#1$/.test(k) ? { findings: [F('code-1', 'medium')], notes: [] }
      : /^code-repair-r\d#1$/.test(k) ? repaired('code-1', ['a.ps1']) : undefined)
    const before = await scenario({ respond: stuck })
    const after = await scenario({ args: { keithRulings: [{ id: 'code-1', ruling: 'Use a 10 second timeout' }] }, respond: stuck })
    assert.strictEqual(after.prompts['code-review-r1#1'], before.prompts['code-review-r1#1'], 'agents before the first repair replay from cache')
    assert.ok(after.prompts['code-repair-r1#1'].includes("Keith's rulings") && after.prompts['code-repair-r1#1'].includes('Use a 10 second timeout'), 'the first repair carries out the ruling')
    assert.ok(!after.prompts['code-repair-r2#1'].includes("Keith's rulings"), 'the next repair is an ordinary one')
    assert.strictEqual(after.out.halted, true)
    assert.ok(/still open after 2 repair rounds: code-1/.test(after.out.stopReason), after.out.stopReason)
    assert.ok(after.calls.includes('code-review-r3#1') && !after.calls.includes('code-repair-r3#1'))
  },
}

;(async () => {
  let failed = 0
  for (const [name, fn] of Object.entries(tests)) {
    try { await fn(); console.log('PASS', name) } catch (e) { failed++; console.log('FAIL', name, '::', e.message) }
  }
  console.log(`${Object.keys(tests).length - failed}/${Object.keys(tests).length} passed`)
  process.exit(failed ? 1 : 0)
})()
