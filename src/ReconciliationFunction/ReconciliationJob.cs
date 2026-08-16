using Microsoft.Azure.Functions.Worker;
using Microsoft.ApplicationInsights;
using Microsoft.Extensions.Logging;

namespace ReconciliationFunction;

public class ReconciliationJob
{
    private readonly ILogger<ReconciliationJob> _logger;
    private readonly IRecordStore _recordStore;
    private readonly TelemetryClient _telemetryClient;

    public ReconciliationJob(ILogger<ReconciliationJob> logger, IRecordStore recordStore, TelemetryClient telemetryClient)
    {
        _logger = logger;
        _recordStore = recordStore;
        _telemetryClient = telemetryClient;
    }

    [Function("NightlyReconciliation")]
    public async Task Run([TimerTrigger("0 0 2 * * *")] TimerInfo timer)
    {
        var (fromUtc, toUtc) = GetYesterdayRangeUtc(DateTimeOffset.UtcNow);

        var orders = await _recordStore.GetOrdersAsync(fromUtc, toUtc);

        _logger.LogInformation("Reconciliation processed {Count} records for range {From} - {To}",
            orders.Count, fromUtc, toUtc);

        // This is the metric the App Insights anomaly alert watches.
        _telemetryClient.TrackMetric("records_processed", orders.Count);

        // Report generation etc. would continue here — omitted for the demo.
    }

    /// <summary>
    /// Computes the UTC range representing "all of yesterday" relative to now.
    /// Per ADR-0001, this must be UTC and the upper bound must be inclusive
    /// of yesterday's final instant.
    /// </summary>
    public static (DateTimeOffset fromUtc, DateTimeOffset toUtc) GetYesterdayRangeUtc(DateTimeOffset nowUtc)
    {
        var todayUtc = nowUtc.Date;
        var yesterdayUtc = todayUtc.AddDays(-1);

        var fromUtc = new DateTimeOffset(yesterdayUtc, TimeSpan.Zero);
        var toUtc = new DateTimeOffset(todayUtc, TimeSpan.Zero); // exclusive end-of-range marker; see GetOrdersAsync

        return (fromUtc, toUtc);
    }
}
