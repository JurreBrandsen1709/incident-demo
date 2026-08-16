# Incident: 2025-11-14 — Reconciliation job processed zero records

**Severity:** Sev3
**Duration:** ~9 hours (overnight, discovered next morning by a customer
report, not by alerting — we had no anomaly alert on `records_processed` at
the time)

## What happened

A change to the reporting date-range helper introduced a timezone mismatch:
the helper switched from `UtcNow` to `DateTime.Now`, and the Function App's
host clock was in a different offset than assumed. The nightly reconciliation
job filtered for "yesterday" using the wrong instant and matched zero
records. No exception was thrown — the query simply returned an empty set,
which the job treated as a valid (if unusual) outcome.

## Root cause

Date-range logic used server-local time instead of UTC, in violation of what
later became ADR-0001.

## Fix

Reverted to `UtcNow`. Added a unit test asserting UTC is used regardless of
host timezone configuration.

## Follow-ups from this incident

- [x] Write ADR-0001 formalizing UTC + inclusive-boundary requirement
- [x] Add anomaly alerting on `records_processed` so this fails loudly next
      time instead of being caught by a customer
- [ ] Audit other scheduled jobs for the same pattern (not yet done)

## Note for future investigators

If you're looking at this because `records_processed` hit zero again: check
whether this is the *same* class of bug (date/timezone/boundary handling in
the range filter) or something new. The alerting from this incident's
follow-up is what caught it this time — which means the underlying pattern
may not be fully fixed across the codebase yet.
