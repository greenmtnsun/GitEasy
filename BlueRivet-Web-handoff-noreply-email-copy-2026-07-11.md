# BlueRivet-Web -> GitEasy handoff: noreply@detentpoint.com copy accuracy

**Date:** 2026-07-11
**From:** BlueRivet-Web (Detent Point website, not yet deployed)
**To:** GitEasy
**Ask:** Confirm whether `noreply@detentpoint.com` actually delivers mail today. The website copy's accuracy depends on your answer, not on anything the website controls.

## What prompted this

Reviewing `BlueRivet-Web/site/src/pages/giteasy-how.html` (line ~117), the copy tells
users: "check your spam folder for email from noreply@detentpoint.com." Keith confirmed
this is not a provisioned M365 mailbox, which raised the question of whether the sentence
is still accurate.

## What I found tracing it

`GitEasy-internal` already owns this end-to-end — nothing about it lives in the website:

- `src/GitEasy.MCP/Services/EmailService.cs:29` hardcodes the default sender:
  `config["GITEASY_FROM_EMAIL"] ?? "GitEasy <noreply@detentpoint.com>"`, sent via Resend.
- `EmailService.cs:42` and `docs/CONNECT.md:145` both tell users to whitelist
  `noreply@detentpoint.com` — same claim as the website copy.
- `deploy/stripe-setup.md:436` documents `GITEASY_FROM_EMAIL` as overridable, defaulting to
  this address, with the parenthetical "(verified Resend domain)" next to the override option
  — implying the default itself needs a verified Resend domain too, but I can't tell from the
  repo alone whether that verification (SPF/DKIM DNS at Cloudflare for detentpoint.com) has
  actually been done.

A "noreply" address doesn't need an M365 inbox to send — Resend just needs the sending
domain verified. So the open question isn't "does a mailbox exist" (it doesn't need to), it's
**"is detentpoint.com verified in Resend so mail from noreply@detentpoint.com actually lands
instead of bouncing/landing in spam by default."**

## The actual ask

1. Check Resend's dashboard (or wherever the domain verification lives) for
   `detentpoint.com` — is SPF/DKIM set up and passing?
2. If yes: the website copy, `EmailService.cs`'s in-app message, and `CONNECT.md` are all
   accurate as written — no change needed anywhere, including the website.
3. If no (or unverified): three places say the same unverified thing (website, in-app
   message, CONNECT.md) and should probably change together, on your side, once you decide
   what the real guidance should be (verify the domain, or generalize the copy to something
   like "check your spam folder for email from GitEasy" without naming an address). GitEasy
   owns that decision since it owns the sender config; happy to make the matching website
   edit once you've settled it, or you're welcome to edit `giteasy-how.html` yourselves if
   that's faster.

No urgency on this — website isn't deployed yet, so there's no live-copy risk in the
meantime.
