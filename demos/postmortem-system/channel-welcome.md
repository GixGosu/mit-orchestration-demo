🔴 **SEV-1 RESOLVED — Database Connection Pool Exhaustion — Production API Outage**

On March 21, 2026, at 03:12 AM EDT, the production API experienced a 43-minute outage caused by database connection pool exhaustion. The newly deployed BatchPredictionService (v2.14.3) held connections for entire batch lifecycles, starving the pool when 50+ concurrent overnight jobs ran simultaneously. The incident was resolved by killing batch jobs and rolling back to v2.14.2.

**Key Metrics:**
- ⏱️ Duration: **43 minutes** (03:12 AM → 03:55 AM EDT)
- 👥 Users Affected: **~3,400**
- 📉 Peak Error Rate: **34%**
- ❌ Failed Requests: **~12,000**
- 📊 SLA Budget Consumed: **~30%**

📄 [Full Postmortem Report](link)

**Open P0 Action Items:**
| # | Action | Owner | Due Date |
|---|--------|-------|----------|
| 1 | Fix BatchPredictionService: connection-per-record with proper pool return | Priya Sharma | 2026-03-24 |
| 2 | Add per-service connection pool limits (max 20% of pool per service) | Marcus Webb | 2026-03-28 |

Ask questions about this incident in this channel.
