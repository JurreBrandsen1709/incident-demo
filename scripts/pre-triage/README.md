# Pre-triage step

`gather-context.sh` is the one place in this pipeline responsible for
turning raw signals into a curated, structured issue for the coding agent.
It never lets the agent query production directly.

## Local/offline mode (default, used for the conference demo)

`gather-context.sh` reads `fixtures/app-insights-anomaly.json` instead of
querying live Azure Monitor. This removes a live-network dependency from the
demo without changing anything about the pipeline's shape.

## Wiring up a real alert

To go from fixture to production:

1. Create a custom metric `records_processed` in your Function App's App
   Insights instance.
2. Create an Azure Monitor alert rule on that metric with an anomaly or
   threshold condition (e.g. "value == 0").
3. Add a webhook action to the alert's Action Group, pointing at a small
   relay (Azure Function, Logic App, or any tiny service) that calls:

   ```
   POST https://api.github.com/repos/<owner>/<repo>/dispatches
   {
     "event_type": "reconciliation-anomaly",
     "client_payload": { "alert_json": "<the alert payload>" }
   }
   ```

4. That triggers `incident-response.yml` via `repository_dispatch`, and
   `gather-context.sh` will use the real payload instead of the fixture.

This relay step needs its own least-privilege treatment — it only needs
permission to fire a `repository_dispatch`, nothing more.
