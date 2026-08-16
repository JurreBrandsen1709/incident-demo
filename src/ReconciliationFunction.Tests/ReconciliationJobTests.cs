using ReconciliationFunction;
using Xunit;

namespace ReconciliationFunction.Tests;

/// <summary>
/// These tests exercise GetYesterdayRangeUtc in isolation, and they pass —
/// that method's date math is correct. This is deliberate: the injected bug
/// for the demo lives in LocalJsonRecordStore.GetOrdersAsync's filtering
/// logic, which nothing here exercises. This is intentional and mirrors a
/// very common real-world gap: the "clean, unit-testable" pure function
/// gets tested; the filtering glue code that consumes it doesn't, because
/// it needs seeded/integration-level data to test meaningfully.
///
/// Part of the demo's debrief: does the agent notice and fix this gap, not
/// just the bug itself? Its system prompt (.github/agents/incident-responder.md)
/// asks it to add a test that would have caught this.
/// </summary>
public class ReconciliationJobTests
{
    [Fact]
    public void GetYesterdayRangeUtc_ReturnsFullUtcDayForYesterday()
    {
        var now = new DateTimeOffset(2026, 8, 16, 10, 30, 0, TimeSpan.Zero);

        var (fromUtc, toUtc) = ReconciliationJob.GetYesterdayRangeUtc(now);

        Assert.Equal(new DateTimeOffset(2026, 8, 15, 0, 0, 0, TimeSpan.Zero), fromUtc);
        Assert.Equal(new DateTimeOffset(2026, 8, 16, 0, 0, 0, TimeSpan.Zero), toUtc);
    }

    [Fact]
    public void GetYesterdayRangeUtc_IsAlwaysUtc_RegardlessOfInputOffset()
    {
        // Passing in a non-UTC offset should not change the computed range,
        // per ADR-0001.
        var nowWithOffset = new DateTimeOffset(2026, 8, 16, 12, 30, 0, TimeSpan.FromHours(5));

        var (fromUtc, toUtc) = ReconciliationJob.GetYesterdayRangeUtc(nowWithOffset.ToUniversalTime());

        Assert.Equal(TimeSpan.Zero, fromUtc.Offset);
        Assert.Equal(TimeSpan.Zero, toUtc.Offset);
    }
}
