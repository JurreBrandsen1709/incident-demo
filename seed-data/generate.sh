#!/usr/bin/env bash
# Regenerates orders.json with timestamps relative to "today", so the demo
# always has valid "yesterday" data no matter when you run it.
#
# Run this once before each rehearsal or before the live talk:
#   ./seed-data/generate.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

YESTERDAY=$(date -u -d "yesterday" +%Y-%m-%d 2>/dev/null || date -u -v-1d +%Y-%m-%d)
TWO_DAYS_AGO=$(date -u -d "2 days ago" +%Y-%m-%d 2>/dev/null || date -u -v-2d +%Y-%m-%d)

cat > "$SCRIPT_DIR/orders.json" <<EOF
[
  { "OrderId": "ORD-1001", "TimestampUtc": "${YESTERDAY}T03:12:00Z", "Amount": 42.50 },
  { "OrderId": "ORD-1002", "TimestampUtc": "${YESTERDAY}T09:47:00Z", "Amount": 18.00 },
  { "OrderId": "ORD-1003", "TimestampUtc": "${YESTERDAY}T14:03:00Z", "Amount": 129.99 },
  { "OrderId": "ORD-1004", "TimestampUtc": "${YESTERDAY}T21:58:00Z", "Amount": 7.25 },
  { "OrderId": "ORD-1005", "TimestampUtc": "${TWO_DAYS_AGO}T11:00:00Z", "Amount": 55.00 }
]
EOF

echo "seed-data/orders.json regenerated with yesterday = $YESTERDAY"
