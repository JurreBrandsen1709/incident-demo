# Agentic Incident Response — GitHub-native starter

This repo is the working demo from the talk *"You already trust an agent to
write your code — here's how much of that trust survives the trip into
production."* It shows a minimal, GitHub-native architecture for handing the
**investigation and first-draft fix** of a production incident to an AI
agent, while keeping every write to production behind a human.

## The trust boundary

```
Detect → Pre-triage → Investigate → Analyze → Propose → PR → Human Review → Merge → Deploy
         ─────────────────────────────────────────────────              ─────────────
              handled by Action + Copilot coding agent                    handled by you
```

The agent never touches production directly. It receives a **curated,
pre-gathered context bundle** (not raw access to your monitoring stack) and
returns a pull request. A human merges. That split isn't a style choice —
it's close to how GitHub's own coding agent is built to work today: issue in,
PR out, sandboxed, firewalled, no native access to external telemetry unless
you explicitly wire it up via MCP.

## What's in here

```
.github/
  workflows/incident-response.yml   # the trigger → pre-triage → issue pipeline
  agents/incident-responder.md      # the coding agent's system prompt / config
scripts/pre-triage/
  gather-context.sh                 # assembles the curated issue from raw signals
  fixtures/                         # simulated App Insights alert for local/offline runs
src/ReconciliationFunction/         # the staged demo app (the thing that breaks)
docs/adr/                           # architecture decision records — retrieval context
docs/incidents/                     # past-incident log — retrieval context
seed-data/                          # fake data for the local/offline demo run
```

## The demo scenario, in short

A nightly Azure Function reconciles "yesterday's" records. A refactor changes
a date-range comparison from `<=` to `<`. Tests still pass (they mock a fixed
instant that doesn't cross the affected boundary). Nothing alarms in CI or
review. The job runs overnight, silently processes **zero records**, and an
App Insights anomaly alert fires on the `records_processed` metric.

That alert triggers `incident-response.yml`, which:

1. Gathers the anomaly evidence, the relevant deploy diff, and — this is the
   minimum bar for this demo — searches `docs/incidents/` and `docs/adr/`
   for anything relevant (there is: an ADR on date-boundary handling, and a
   past incident with the same failure shape)
2. Packages all of it into a single, structured GitHub Issue
3. Assigns the issue to the GitHub Copilot coding agent
4. The agent investigates using only what's in the issue plus its scoped
   tools, and opens a PR with its root-cause analysis and a proposed fix
5. A human reviews and merges

## Running this yourself

This repo runs **fully locally by default** (Azurite emulation + a seeded
dataset + a fixture standing in for the live App Insights query), so you can
try the whole pipeline without a live Azure subscription. See
`src/ReconciliationFunction/README.md` for local run instructions, and
`scripts/pre-triage/README.md` for how to point the pre-triage step at a
real Azure Monitor alert instead of the fixture when you're ready.

## Extending this

This repo intentionally stops at "look up past incidents and ADRs by keyword
match." The natural next steps — not built here, but straightforward from
this shape:

- **RAG over your full internal documentation** (runbooks, architecture
  wikis, postmortems) instead of a flat folder search
- **Knowledge-graph-based routing** — instead of one agent and one repo,
  route the incident to the right service owner/team based on a dependency
  graph
- **Multi-agent coordination** for incidents that span services

None of that changes the trust boundary above. It only makes the "gather
context" step smarter before it ever reaches the agent.
