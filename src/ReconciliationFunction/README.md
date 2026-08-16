# Reconciliation Function — local/offline run

This runs fully locally, no live Azure subscription required.

## Prerequisites

- .NET 8 SDK
- Azure Functions Core Tools v4
- Azurite (for local storage emulation): `npm install -g azurite`

## Run it

```bash
# from repo root
./seed-data/generate.sh          # refresh seed data with today's dates
cp src/ReconciliationFunction/local.settings.json.example \
   src/ReconciliationFunction/local.settings.json

azurite &                        # in one terminal
cd src/ReconciliationFunction
func start                       # in another
```

The timer trigger fires on a schedule (`0 0 2 * * *`, i.e. 2am UTC). To
trigger it on demand instead of waiting — which is what you want on stage —
call the admin endpoint:

```bash
curl -X POST http://localhost:7071/admin/functions/NightlyReconciliation \
  -H "Content-Type: application/json" -d "{}"
```

With the bug in place (the default state of this repo), this will log
`records_processed: 0` regardless of the seeded data. Deploying the fix
(reverting the filter in `IRecordStore.cs`) and re-running should show
`records_processed: 4`.

## Running the tests

```bash
cd src/ReconciliationFunction.Tests
dotnet test
```

These pass either way — see the comment at the top of
`ReconciliationJobTests.cs` for why that's the point.
