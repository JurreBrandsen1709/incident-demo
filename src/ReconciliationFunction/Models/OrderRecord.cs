namespace ReconciliationFunction.Models;

public record OrderRecord(string OrderId, DateTimeOffset TimestampUtc, decimal Amount);
