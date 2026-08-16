using ReconciliationFunction.Models;

namespace ReconciliationFunction;

public interface IRecordStore
{
    Task<IReadOnlyList<OrderRecord>> GetOrdersAsync(DateTimeOffset fromUtc, DateTimeOffset toUtc);
}

/// <summary>
/// Reads seeded order data from seed-data/orders.json. Stands in for a real
/// database connection so the demo can run fully offline. See README.md at
/// the repo root for how this maps to a real Azure SQL / Cosmos backend.
/// </summary>
public class LocalJsonRecordStore : IRecordStore
{
    private readonly string _seedDataPath;

    public LocalJsonRecordStore()
    {
        _seedDataPath = Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "seed-data", "orders.json");
    }

    public async Task<IReadOnlyList<OrderRecord>> GetOrdersAsync(DateTimeOffset fromUtc, DateTimeOffset toUtc)
    {
        var json = await File.ReadAllTextAsync(_seedDataPath);
        var all = System.Text.Json.JsonSerializer.Deserialize<List<OrderRecord>>(json,
            new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true })
            ?? new List<OrderRecord>();

        return all.Where(o => o.TimestampUtc >= fromUtc && o.TimestampUtc < toUtc).ToList();
    }
}
