# ADR-0001: Date range boundaries must be inclusive and UTC-based

**Status:** Accepted
**Date:** 2025-06-02

## Context

Several of our scheduled jobs process "yesterday's" records by filtering on
a date range. We've had ambiguity in the past about whether range boundaries
should be inclusive or exclusive, and whether to use server-local time or
UTC.

## Decision

All date-range filters over event/record timestamps must:

1. Use UTC exclusively — never `DateTime.Now` or server-local time.
2. Use an **inclusive** upper bound (`<=`) when the range represents "all of
   day X," since a record timestamped exactly at day X's final instant is
   still part of day X.

## Consequences

Any refactor touching date-range logic in scheduled/batch jobs should be
reviewed against this ADR specifically — boundary changes are easy to get
subtly wrong and existing unit tests often don't exercise the exact
boundary instant, so CI passing is not sufficient evidence of correctness
here.
