# Incident Log — Database Connection Pool Exhaustion
## Meridian Labs — Production Incident 2026-03-21

### Slack Thread: #incidents — "API 500s spiking"

**03:12 AM** — [PagerDuty] ALERT: API error rate >5% on prod-api-cluster-east
**03:14 AM** — [Sarah Chen, SRE] Acknowledged. Checking dashboards.
**03:16 AM** — [Sarah Chen] Error rate at 12% and climbing. All 500s are coming from /api/v2/predictions endpoint. Grafana shows normal traffic volume.
**03:18 AM** — [Sarah Chen] Database connection pool is at 100% capacity on primary RDS instance. No connections being released. This is the bottleneck.
**03:20 AM** — [Sarah Chen] Paging @marcus (DB lead) and @priya (backend lead)
**03:23 AM** — [Marcus Webb, DB Lead] Online. Checking RDS metrics. Active connections at 500/500 (max pool). Wait queue growing. Something is holding connections open.
**03:27 AM** — [Priya Sharma, Backend Lead] Checking recent deployments. We shipped v2.14.3 yesterday at 5 PM — new batch prediction pipeline.
**03:31 AM** — [Marcus Webb] Found it. Slow query log shows the new batch_predict stored procedure is running 45-second queries and not releasing connections. Each batch job holds a connection for the entire batch instead of per-record.
**03:33 AM** — [Sarah Chen] Error rate now at 34%. Customer-facing dashboard is down. Mobile app returning errors.
**03:35 AM** — [Priya Sharma] Confirmed. The new BatchPredictionService opens a connection at the start of the batch and doesn't close it until all records are processed. With 50+ concurrent batches running overnight, that's 50+ connections held for 10+ minutes each.
**03:37 AM** — [Sarah Chen] Mitigation option 1: Kill the batch jobs. Option 2: Increase pool size. Option 3: Rollback to v2.14.2.
**03:38 AM** — [Marcus Webb] Increasing pool size is a bandaid — we'll hit memory limits. I say kill the batch jobs now, rollback the deployment.
**03:39 AM** — [Priya Sharma] Agreed. Rolling back. ETA 8 minutes.
**03:41 AM** — [Sarah Chen] Killing all active batch prediction jobs. Pool connections dropping — 500 → 420 → 380...
**03:44 AM** — [Sarah Chen] Pool at 200. Error rate dropping. 34% → 18% → 9%.
**03:47 AM** — [Priya Sharma] Rollback to v2.14.2 complete. Deployment verified.
**03:49 AM** — [Sarah Chen] Error rate at 1.2%. Pool connections at 85/500. Customer dashboard recovering. Mobile app responding.
**03:55 AM** — [Sarah Chen] All clear. Error rate <0.5%. Pool stable at ~80 connections. Declaring incident resolved.
**04:00 AM** — [Marcus Webb] For the record: ~12,000 API requests failed during the 43-minute window. Estimated 3,400 unique users affected. Batch prediction results for overnight jobs will need to be re-run.
**04:05 AM** — [Priya Sharma] I'll fix the connection handling in BatchPredictionService tomorrow — connection-per-record with proper pooling. Will also add a circuit breaker so a single service can't exhaust the pool.
**04:10 AM** — [Sarah Chen] Action items logged. Scheduling postmortem for Monday 10 AM. Good work everyone.

### Additional Context
- Meridian Labs SLA: 99.9% uptime (this incident consumed ~30% of monthly error budget)
- The batch prediction pipeline was a new feature requested by Enterprise customers
- No pre-production load testing was done on the batch pipeline with concurrent jobs
- Connection pool monitoring alert existed but threshold was set at 95% — it fired at 03:12 but by then pool was already at 100%
- Similar incident occurred 6 months ago (INC-2025-09-14) with a different service exhausting connections — same root cause pattern (connection not released)
- Previous incident's action item "Add per-service connection pool limits" was marked P2 and never completed
