#!/usr/bin/env bash
# gather-context.sh
#
# This is the "pre-triage" step of the trust boundary. It runs BEFORE the
# agent ever sees anything. Its job is to turn raw, untrusted signals
# (alert payloads, log lines, telemetry) into a single, structured,
# reviewed context bundle for the coding agent.
#
# Why this step exists, not just "let the agent query App Insights itself":
#   1. GitHub's coding agent has no native access to external telemetry —
#      you'd have to grant it an MCP server for that, which is a much larger
#      trust surface than handing it pre-gathered evidence.
#   2. Raw log/telemetry content can contain attacker- or user-influenced
#      strings. This script is the one place responsible for treating that
#      content as DATA, never as instructions, before it lands in an issue
#      the agent will read as trusted context. See the sanitization note
#      near the bottom.
#
# Usage: gather-context.sh <alert_json_or_empty> <use_fixture: true|false>

set -euo pipefail

ALERT_JSON="${1:-}"
USE_FIXTURE="${2:-true}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- 1. Get the anomaly evidence ------------------------------------------
if [ "$USE_FIXTURE" = "true" ] || [ -z "$ALERT_JSON" ]; then
  ANOMALY_JSON="$(cat "$SCRIPT_DIR/fixtures/app-insights-anomaly.json")"
else
  ANOMALY_JSON="$ALERT_JSON"
fi

METRIC_VALUE=$(echo "$ANOMALY_JSON" | grep -o '"records_processed":[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "unknown")
EXPECTED_RANGE=$(echo "$ANOMALY_JSON" | grep -o '"expected_range":[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "unknown")

# --- 2. Get the recent deploy diff -----------------------------------------
# Last commit touching the reconciliation job's date-range filtering logic.
DEPLOY_DIFF=$(git -C "$REPO_ROOT" log -1 --format="%H %s" -- src/ReconciliationFunction/IRecordStore.cs 2>/dev/null || echo "no recent changes found")
DIFF_CONTENT=$(git -C "$REPO_ROOT" log -1 -p -- src/ReconciliationFunction/IRecordStore.cs 2>/dev/null | head -100 || echo "")

# --- 3. Search past incidents and ADRs (the minimum retrieval bar) --------
# Simple keyword search over docs/. This is intentionally not RAG — see the
# "Extending this" section of the top-level README for what a production
# version of this step would look like.
RELEVANT_INCIDENTS=$(grep -riL "no-match-placeholder" "$REPO_ROOT/docs/incidents/" 2>/dev/null || true)
RELEVANT_INCIDENTS=$(grep -ril "zero records\|date range\|reconciliation" "$REPO_ROOT/docs/incidents/" 2>/dev/null || true)
RELEVANT_ADRS=$(grep -ril "date\|utc\|boundary\|timezone" "$REPO_ROOT/docs/adr/" 2>/dev/null || true)

# --- 4. Assemble the curated issue -----------------------------------------
# IMPORTANT sanitization note: everything interpolated below is either (a)
# structured data from our own monitoring (ANOMALY_JSON, METRIC_VALUE), or
# (b) our own repo's commit history and docs. None of it is unreviewed
# external/user-facing text. If you extend this script to pull in raw log
# lines that could contain user-influenced content (request bodies, headers,
# free-text error messages), treat that content as a quoted, clearly-fenced
# DATA block in the issue — never as prose the agent might read as
# instructions. This is the control point for the prompt-injection class
# described in the talk's security segment.

cat <<EOF
## Incident: Reconciliation job processed zero records

**Detected by:** App Insights anomaly alert on \`records_processed\` metric
**Observed value:** $METRIC_VALUE
**Expected range:** $EXPECTED_RANGE

### Evidence (raw, untouched)
\`\`\`json
$ANOMALY_JSON
\`\`\`

### Recent deploy touching this code path
\`$DEPLOY_DIFF\`

<details>
<summary>Diff</summary>

\`\`\`diff
$DIFF_CONTENT
\`\`\`
</details>

### Relevant past incidents
${RELEVANT_INCIDENTS:-none found}

### Relevant ADRs
${RELEVANT_ADRS:-none found}

---

**Task for the agent:** Investigate why this job processed zero records.
Use the evidence above, the linked past incident(s), and the linked ADR(s).
Identify the root cause and open a pull request with a fix. Do not modify
anything outside \`src/ReconciliationFunction/\`. Include your reasoning and
which sources informed your conclusion in the PR description.
EOF
