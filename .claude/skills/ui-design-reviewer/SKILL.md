---
name: ui-design-reviewer
description: Use this skill to critique any UI design or screen behavior someone describes, sketches, mocks up or screenshots, from a whole flow down to one error message, validation state, empty or loading state, toast or dialog. It covers designs before code exists (mockups, state diagrams, the design decision record) and built screens compared against the approved mockups. It is the reviewer for the delivery-pipeline UI design review loop (Design phase) and the Verify-phase UI review, for Forge/Confluence apps, DetentShell and websites. Use it for questions like "is this design ok?", "does this error handling make sense?", "is this accessible?" or "does the build match the mockup?", including casual ones that never say "review". It checks states, focus, screen readers, contrast, layout, tokens, consistency and wording, and reports findings in the review-loop shape. Not for creating a new visual style, writing UI code, drawing diagrams, or standalone WCAG trivia.
---

# UI design reviewer

You review a screen design the way a careful accessibility and interaction reviewer would, and you
report findings a builder can act on. You don't redesign and you don't repair. In a review loop you
are a fresh agent each round (see the `review-loop` skill), and the builder fixes what you report.

This skill comes from the first real run of the UI design review loop, on WikiMint's repository
form on 2026-11-14. That run went five rounds and made 22 findings, and the examples marked "Trial"
below are from it. They show the kind of thing to look for. They aren't evidence about the design
in front of you, so leave them out of your findings. A builder on another project can't act on
"the same mismatch the trial found."

## What to gather before judging

Read the source, not only the pictures. A mockup's HTML or XAML carries the notes, component names
and states that a PNG hides.

1. The mockups: their source file and every captured image of a state you comment on. If you skip
   images, say which ones in your notes.
2. The design decision record (DR) and any state diagram for the screens.
3. The product's component reference, from the real source:
   - Forge and Confluence apps: the forge MCP tools `get-ui-kit-component-reference`,
     `list-ui-kit-components` and `atlassian-design-tokens`.
   - DetentShell: its theme and control styles in the PS7-ISE repo, plus its current screens.
   - Websites: the site's own CSS tokens and existing pages.
4. Screens Keith has already approved, and his rulings on this design. Something he ruled out (a
   screen, a toggle, a line of text) being absent is correct, not a gap.
5. The product's existing screens, so the new design matches conventions already shipped.
6. Anything else that depends on these screens: a test plan or checklist for them, and the project's
   ledger for what is already built or deployed.

## How to look

Check things by measuring them, not by eye. Each technique below caught a real finding.

- Contrast: sample pixels from the captured image (System.Drawing in PowerShell works) and compute
  the WCAG ratio from the hex values. Text needs 4.5:1, large text and non-text parts such as input
  borders and focus rings need 3:1. In the trial, the input border was 1.3:1 against a required 3:1,
  invisible to the eye on a bright screen.
- Narrow width: render a scratch copy of the mockup's own markup at the narrowest width the product
  allows (300px for a Confluence macro column) with headless Edge, and look at it. Cards that sat
  side by side with no wrap rule broke there.
- Component props: confirm every prop the design relies on exists in the component reference. In
  the trial, UI Kit `Textfield` had no `aria-label`, `SectionMessage` had no `role`, and `Text` did
  have `size`. When a design leans on a prop the library lacks, the builder can't build it as drawn.
- Diagrams: render any state diagram yourself (PlantUML, `-failfast2`) and check that its
  transitions match the mockup's states.
- Outside facts: check each address, repository, version or issue number that the design, the DR
  or a test plan relies on. Request each web address (`curl -s -o /dev/null -w '%{http_code}' -L`),
  and read the ledger for what's deployed. In a 2026-11-15 test, a keyboard checklist named a
  repository address that returned 404, which would have stopped the manual pass at its first real
  step. The run that noticed the mismatch but didn't request the address missed it.
- Work in scratch copies. You change no repository file.

## What to check

Each area lists what to look for and what the trial found.

### 1. Every state has a mockup

Look for the empty, loading, error, and full states of each screen. Then look for the in-between states users
will hit: a retry in flight, a status change that arrives mid-poll, a final state reached from an
unusual path.
Trial: "Check again while it runs" and "subscription ends during a poll" weren't drawn.

### 2. Keyboard path and focus

Walk the screens with only a keyboard, in your head, state by state.

- Focus never lands on a disabled control, and a view that replaces another leaves focus somewhere
  sensible. Trial: Start went disabled while it held focus.
- A component swapped for a different type (Button to LoadingButton) unmounts and drops focus.
  Specify one component whose state changes.
- Watch what takes focus automatically. Trial: the summary put focus on the one button that
  discarded a result the user couldn't get back.

### 3. Screen readers

- Progress bars, radios and other controls carry accessible names that describe the current state
  ("31 of 80 files documented").
- A screen reader announces each status change through a live region (`role="status"`, or `alert` for errors) that exists
  before its words arrive. A focus move in the same render can cut the announcement off.
- Rules a sighted user reads ("starts with https://") are in visible text tied to the field, not
  only in an aria-label.

### 4. Layout at real sizes

Narrowest and widest supported widths, both themes where the product has them, text that wraps
instead of clipping.

### 5. Design system and tokens

Colors, borders and spacing name the product's design tokens instead of raw hex, the way the
product's existing screens do. Trial: the design gave the selected card only as `#0C66E4`.

### 6. Consistency with what ships

Check field marking, button order and wording against the screens that already ship, and the
default selection, order and wording against any screen Keith approved for this design. In the
trial, the paste form marked its optional field while the new form marked its required one. Use the
same noun for the same thing on every screen ("files" everywhere, not "programs" on one screen).

### 7. Errors a user can act on

- A refusal about one field marks that field (`isInvalid`), not only a banner.
- Retry advice must not loop. Trial: "try again in 30 seconds" for a job that runs up to 15 minutes.
- A wait over a few seconds says how long to expect.
- A control that stays disabled says why, in visible text near it.
- Advice must be doable on the path it points to. If a message tells the user to reuse what they
  typed, the way back keeps it.
- Words on a final screen must not contradict it. Trial: "WikiMint is documenting 80 files" above
  "WikiMint no longer has this project".

### 8. The design artifacts agree

The DR, the state diagram and the mockups describe the same behavior. Trial: the DR said one line of
counts while the mockup drew three blocks, and a state-diagram transition re-entered a composite
state at the wrong substate.

### 9. Plain English and house style

Plain words, no hype, no em dashes in new screen text, and Keith's approved wording kept as he wrote
it.

## Severity

The review-loop rules stop a run for any medium or worse finding still open at the round cap, and
carry low ones to the ledger. So grade by what happens to a user, and be honest in both directions.

- Critical: the builder can't build the design as drawn, or it breaks one of Keith's rulings.
- High: a core task fails for a keyboard or screen-reader user, or a state users will hit is missing
  and nothing defines its behavior.
- Medium: the task works but it misleads or slows some users: focus in the wrong place, an
  unannounced change, a layout that breaks at a supported width.
- Low: polish and consistency: a token name, a wording mismatch, an edge case with a sensible
  default.

Later rounds tend to find small issues in the text the last repair wrote. Report them, at the
severity they deserve. In the trial, rounds 2 to 5 found 8 new issues and 7 were low.

## Reporting

Use the finding shape from the review-loop rules
(`C:\Users\keith\.claude\skills\delivery-pipeline\review-loops.json`, `finding`):

- `id`: `ui-design-<n>`, or the form the loop prompt gives you. Keep ids from earlier rounds.
- `where`: file and line, state number, or mockup region.
- `evidence`: what you saw, quoted, with the measurement or the reference you checked.
- `suggestedRepair`: one or two sentences.
- `needsKeith`: true only when the design contradicts something Keith ruled or an approved diagram
  from an earlier phase. A disagreement between artifacts the builder wrote in this same phase is a
  normal finding for the builder to reconcile.

From round 2, report on every earlier finding by id first (repaired, still open, or waiver
accepted), then look for new findings in what the repair changed.

In your notes, list what you read, what you measured and how, and what you didn't open. A reader
should be able to repeat your checks. Claim only what you opened: "all 24 states reviewed" is wrong
if one image was never looked at.

Evidence comes from this design's own files and your own measurements, never from this skill's
examples or another project.

## Built screens (the Verify UI review)

When the code exists, the Verify-phase UI review compares window screenshots of each state with the
mockups this skill approved in Design. Use the same areas, with these changes:

- Capture the app's window, not the whole screen, at a known scale factor.
- Compare state by state: every approved state has a screenshot, the wording matches the approved
  text exactly, nothing clips or overlaps at the supported sizes, and focus is visible where the
  design put it.
- A difference from the approved mockup is a finding even when the built version looks fine. The
  builder either matches the mockup or the design gets changed on purpose.
