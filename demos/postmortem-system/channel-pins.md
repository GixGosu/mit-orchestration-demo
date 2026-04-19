📊 **Incident Summary**

**Database Connection Pool Exhaustion — Production API Outage**
**Severity:** SEV-1 | **Date:** 2026-03-21 | **Duration:** 43 minutes | **Status:** Resolved

On March 21, 2026, at 03:12 AM EDT, Meridian Labs experienced a 43-minute production API outage caused by database connection pool exhaustion. The newly deployed BatchPredictionService (v2.14.3) held database connections for entire batch lifecycles instead of releasing them per-record, causing 50+ concurrent overnight batch jobs to starve the 500-connection pool. Approximately 12,000 API requests failed, impacting ~3,400 unique users, with the error rate peaking at 34%. The incident was resolved by killing active batch jobs and rolling back to v2.14.2, consuming ~30% of the monthly SLA error budget.

**Impact Metrics:**
- ⏱️ Duration: 43 minutes (03:12 AM → 03:55 AM EDT)
- ❌ Failed Requests: ~12,000
- 👥 Users Affected: ~3,400
- 📉 Peak Error Rate: 34%
- 📊 SLA Budget Consumed: ~30%

---

⏱️ **Timeline**

| Time | Actor | Event | Phase |
|------|-------|-------|-------|
| 03:12 AM | PagerDuty | ALERT: API error rate >5% on prod-api-cluster-east | 🔴 Detection |
| 03:14 AM | Sarah Chen (SRE) | Acknowledged alert. Checking dashboards. | 🔴 Detection |
| 03:16 AM | Sarah Chen (SRE) | Error rate at 12% and climbing. All 500s from /api/v2/predictions. Normal traffic volume. | 🟡 Investigation |
| 03:18 AM | Sarah Chen (SRE) | DB connection pool at 100% capacity on primary RDS. No connections being released. | 🟡 Investigation |
| 03:20 AM | Sarah Chen (SRE) | Paged Marcus Webb (DB Lead) and Priya Sharma (Backend Lead). | 🟡 Investigation |
| 03:23 AM | Marcus Webb (DB Lead) | Online. Active connections at 500/500. Wait queue growing. | 🟡 Investigation |
| 03:27 AM | Priya Sharma (Backend Lead) | Checking deployments. v2.14.3 shipped yesterday — new batch prediction pipeline. | 🟡 Investigation |
| 03:31 AM | Marcus Webb (DB Lead) | Found root cause: batch_predict procedure running 45s queries, not releasing connections. | 🟡 Investigation |
| 03:33 AM | Sarah Chen (SRE) | Error rate at 34%. Dashboard down. Mobile app returning errors. | 🟡 Investigation |
| 03:35 AM | Priya Sharma (Backend Lead) | Confirmed: BatchPredictionService holds connection for full batch. 50+ batches × 10+ min = pool starvation. | 🟡 Investigation |
| 03:37 AM | Sarah Chen (SRE) | Proposed options: (1) Kill batch jobs, (2) Increase pool size, (3) Rollback to v2.14.2. | 🟢 Mitigation |
| 03:38 AM | Marcus Webb (DB Lead) | Advised against pool increase (bandaid). Recommended: kill jobs + rollback. | 🟢 Mitigation |
| 03:39 AM | Priya Sharma (Backend Lead) | Agreed. Initiated rollback. ETA 8 minutes. | 🟢 Mitigation |
| 03:41 AM | Sarah Chen (SRE) | Killing batch jobs. Pool dropping: 500 → 420 → 380. | 🟢 Mitigation |
| 03:44 AM | Sarah Chen (SRE) | Pool at 200. Error rate: 34% → 18% → 9%. | 🟢 Mitigation |
| 03:47 AM | Priya Sharma (Backend Lead) | Rollback to v2.14.2 complete. Deployment verified. | 🟢 Mitigation |
| 03:49 AM | Sarah Chen (SRE) | Error rate at 1.2%. Pool at 85/500. Dashboard recovering. Mobile responding. | 🔵 Resolution |
| 03:55 AM | Sarah Chen (SRE) | All clear. Error rate <0.5%. Pool stable at ~80. Incident resolved. | 🔵 Resolution |
| 04:00 AM | Marcus Webb (DB Lead) | Final impact: ~12,000 failed requests, ~3,400 users affected. Batch results need re-run. | ⚪ Follow-up |
| 04:05 AM | Priya Sharma (Backend Lead) | Will fix connection handling and add circuit breaker. | ⚪ Follow-up |
| 04:10 AM | Sarah Chen (SRE) | Action items logged. Postmortem scheduled for Monday 10 AM. | ⚪ Follow-up |

---

🔍 **Root Cause**

**5 Whys Analysis:**

1. **Why did the API return 500 errors?**
   → Database connection pool exhausted (500/500 connections in use)

2. **Why was the pool exhausted?**
   → BatchPredictionService held connections for entire batch lifecycle instead of per-record

3. **Why did it hold connections that long?**
   → Connection-per-batch design: one connection opened at batch start, not released until all records processed. With 50+ concurrent overnight batches × 10+ min each = pool starvation

4. **Why wasn't this caught before production?**
   → No load testing performed on batch pipeline with concurrent jobs. Feature shipped without performance validation.

5. **Why no load testing?**
   → Feature was fast-tracked for enterprise customer deadline. Standard perf testing checklist was skipped.

**Contributing Factors:**
- Connection pool alert threshold set at 95% — fired at 03:12 when pool was already at 100%. Too late.
- Previous incident INC-2025-09-14 had same root cause pattern. Its P2 action item "Add per-service connection pool limits" was never completed.
- No per-service connection limits — any single service can consume the entire pool.
- BatchPredictionService code review didn't flag the connection lifecycle pattern.

---

✅ **Action Items**

| # | Action | Owner | Priority | Due Date | Status |
|---|--------|-------|----------|----------|--------|
| 1 | Fix BatchPredictionService: connection-per-record with proper pool return | Priya Sharma | P0 | 2026-03-24 | Open |
| 2 | Add per-service connection pool limits (max 20% of pool per service) | Marcus Webb | P0 | 2026-03-28 | Open |
| 3 | Lower connection pool alert threshold from 95% to 80% | Sarah Chen | P1 | 2026-03-22 | Open |
| 4 | Implement circuit breaker: reject new connections when pool >90% | Priya Sharma | P1 | 2026-03-31 | Open |
| 5 | Mandatory load testing gate for all new data pipeline features | Engineering Lead | P1 | 2026-04-07 | Open |
| 6 | Audit ALL open P2+ action items from previous incidents | Sarah Chen | P2 | 2026-04-14 | Open |
| 7 | Add canary deployment requirement for services touching shared resources | Jordan Kim | P2 | 2026-04-14 | Open |

---

💡 **Lessons Learned**

1. **P2 action items from previous incidents are not optional.** The exact same class of bug hit us twice because we deprioritized the fix.

2. **Load testing is mandatory for features that touch shared resources** (DB pools, caches, queues). No exceptions for customer deadlines.

3. **Alert thresholds should fire with margin to act** — 80% gives you time, 95% gives you a notification that you're already down.

4. **Connection lifecycle is a code review checkpoint.** Any code that opens a long-lived connection to a shared pool needs explicit scrutiny.

**Related Incident:** INC-2025-09-14 — Connection pool exhaustion caused by ReportingService. Same pattern: single service consuming entire pool. P2 action item ("per-service pool limits") was never implemented, directly contributing to this incident.
