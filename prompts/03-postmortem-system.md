# Incident Postmortem System — Orchestration Task

You are the lead orchestrator for building an incident postmortem system. Your job is coordination: spawn agents, sequence phases, merge outputs. You do NOT do the building or verification yourself.

## Project Output Directory
`./demos/postmortem-system/` (relative to repo root)

## Input
Incident log: `./sample-data/incident-log.md` (relative to repo root)

---

## Phase 1: Parallel Build (spawn these simultaneously)

### Agent A — Incident Analyst
**Task:** Analyze the raw incident log and produce a complete structured postmortem analysis. Read the incident log file thoroughly — every detail matters.
- Output: `channel-context.md`

**Analysis to produce:**
- **Incident Metadata:**
  - Title: Database Connection Pool Exhaustion — Production API Outage
  - Severity: SEV-1 (full customer-facing outage, >10% error rate, SLA impact)
  - Date: 2026-03-21
  - Duration: 43 minutes (03:12 AM → 03:55 AM EDT)
  - Status: Resolved
- **Executive Summary:** 3-4 sentences covering what happened, business impact, how it was resolved, current state. Concise enough for a VP to read in 15 seconds.
- **Detailed Timeline:** Every event from the incident log with:
  - Timestamp (exact, from log)
  - Actor (who did/said it)
  - Action (what happened)
  - Phase: 🔴 Detection (03:12–03:16), 🟡 Investigation (03:16–03:37), 🟢 Mitigation (03:37–03:49), 🔵 Resolution (03:49–03:55), ⚪ Follow-up (03:55+)
- **Impact Assessment:**
  - Duration: 43 minutes
  - Failed API requests: ~12,000
  - Unique users affected: ~3,400
  - Error rate peak: 34%
  - SLA impact: ~30% of monthly error budget consumed (SLA: 99.9%)
  - Revenue impact: Estimate based on API-driven product usage
  - Downstream: Overnight batch prediction results lost, require re-run
  - Customer-facing: Dashboard down, mobile app returning errors
- **Root Cause Analysis — 5 Whys:**
  1. Why did the API return 500 errors? → Database connection pool exhausted (500/500 connections in use)
  2. Why was the pool exhausted? → BatchPredictionService held connections for entire batch lifecycle instead of per-record
  3. Why did it hold connections that long? → Connection-per-batch design: one connection opened at batch start, not released until all records processed. With 50+ concurrent overnight batches × 10+ min each = pool starvation
  4. Why wasn't this caught before production? → No load testing performed on batch pipeline with concurrent jobs. Feature was shipped without performance validation.
  5. Why no load testing? → Feature was fast-tracked for enterprise customer deadline. Standard perf testing checklist was skipped.
- **Contributing Factors:**
  - Connection pool alert threshold set at 95% — fired at 03:12 when pool was already at 100%. Too late.
  - Previous incident INC-2025-09-14 had same root cause pattern (different service exhausting connections). Its P2 action item "Add per-service connection pool limits" was never completed.
  - No per-service connection limits — any single service can consume the entire pool.
  - BatchPredictionService code review didn't flag the connection lifecycle pattern.
- **What Went Well:**
  - Fast detection-to-resolution: 43 minutes total, 12 minutes from page to identification
  - Team mobilized at 3 AM without hesitation
  - Correct tactical decision: rollback to v2.14.2 instead of bandaid (increasing pool size)
  - Clear communication in incident channel throughout
  - Sarah (SRE) drove mitigation effectively — killed batch jobs while Priya rolled back
- **What Went Wrong:**
  - No pre-production load testing for the batch pipeline feature
  - Previous incident's P2 action item was never completed (6 months overdue)
  - Alert threshold was too high (95% = already exhausted in practice)
  - Connection lifecycle pattern wasn't caught in code review
  - No circuit breaker exists for connection pool exhaustion
  - Batch pipeline launched without a rollback plan or canary deployment
- **Action Items:**
  | # | Action | Owner | Priority | Due Date | Status |
  |---|--------|-------|----------|----------|--------|
  | 1 | Fix BatchPredictionService: connection-per-record with proper pool return | Priya Sharma | P0 | 2026-03-24 | Open |
  | 2 | Add per-service connection pool limits (max 20% of pool per service) | Marcus Webb | P0 | 2026-03-28 | Open |
  | 3 | Lower connection pool alert threshold from 95% to 80% | Sarah Chen | P1 | 2026-03-22 | Open |
  | 4 | Implement circuit breaker: reject new connections when pool >90% | Priya Sharma | P1 | 2026-03-31 | Open |
  | 5 | Mandatory load testing gate for all new data pipeline features | Engineering Lead | P1 | 2026-04-07 | Open |
  | 6 | Audit ALL open P2+ action items from previous incidents | Sarah Chen | P2 | 2026-04-14 | Open |
  | 7 | Add canary deployment requirement for services touching shared resources | Jordan Kim | P2 | 2026-04-14 | Open |
- **Lessons Learned:**
  1. P2 action items from previous incidents are not optional. The exact same class of bug hit us twice because we deprioritized the fix.
  2. Load testing is mandatory for features that touch shared resources (DB pools, caches, queues). No exceptions for customer deadlines.
  3. Alert thresholds should fire with margin to act — 80% gives you time, 95% gives you a notification that you're already down.
  4. Connection lifecycle is a code review checkpoint. Any code that opens a long-lived connection to a shared pool needs explicit scrutiny.
- **Related Incidents:** INC-2025-09-14 — Connection pool exhaustion caused by ReportingService. Same pattern: single service consuming entire pool. P2 action item from that incident ("per-service pool limits") was never implemented.

### Agent B — Report Designer
**Task:** Build the postmortem report as a single HTML file. Get all content from Agent A's `channel-context.md`. Every number, name, and timestamp must match exactly.
- **Header:** Incident title in large type. SEV-1 badge (red background, white text). Date. Duration (43 min). "RESOLVED" badge (green). Last updated timestamp.
- **Executive Summary:** Highlighted box (dark background, light text) immediately below header. 3-4 sentences.
- **Visual Timeline (centerpiece of the page):**
  - Vertical timeline, left-aligned
  - Each event: colored node (🔴🟡🟢🔵 mapped to phase), timestamp, actor name in bold, description
  - Click to expand: additional details for that event
  - Color legend at top of timeline section
  - Subtle connecting line between nodes
- **Impact Dashboard:** 4-6 metric cards in a row:
  - Duration: "43 min" with clock icon
  - Failed Requests: "~12,000" with warning icon
  - Users Affected: "~3,400" with person icon
  - Peak Error Rate: "34%" with chart icon
  - SLA Budget Used: "~30%" with gauge visual (circular progress that fills to 30%)
- **Root Cause — 5 Whys:** Drill-down presentation:
  - Show "Why #1" initially
  - Click "Why?" button to reveal next level
  - Each level indented further, with an arrow connecting them
  - Visual chain from symptom → root cause
- **What Went Well / Wrong:** Two columns side by side
  - Well: green left border, ✅ icon per item
  - Wrong: red left border, ❌ icon per item
- **Action Items Table:**
  - Sortable columns: #, Action, Owner, Priority, Due Date, Status
  - Priority badges: P0 = red, P1 = orange, P2 = yellow
  - Filter buttons: All | P0 | P1 | P2
  - Status badge: Open = blue outline
- **Lessons Learned:** Individual callout cards with 💡 icon, numbered, subtle background highlight
- **Related Incidents:** Link box mentioning INC-2025-09-14 with brief description and connection to current incident
- **Design:**
  - Dark theme: background #0d1117, card backgrounds #161b22, text #c9d1d9
  - Status colors: red #f85149 (severity/P0), orange #d29922 (investigation/P1), yellow #e3b341 (P2), green #3fb950 (resolved/well), blue #58a6ff (info/detection)
  - Typography: system font stack, generous line-height (1.6), clear hierarchy
  - Lots of whitespace between sections
  - Timeline nodes: 12px circles with 2px connecting line
  - Print-friendly: @media print removes dark background, uses black text, hides interactive elements
  - No external CSS frameworks
- Output: `index.html`

### Agent C — Channel Content Formatter
**Task:** Create ready-to-post Mattermost channel content from Agent A's analysis.
- Output `channel-welcome.md`: First message for `#postmortem-2026-03-23`. Format:
  - 🔴 **SEV-1 RESOLVED** header
  - Brief summary (2-3 sentences)
  - Key metrics (duration, users, error rate)
  - Link to full report (placeholder: `[Full Postmortem Report](link)`)
  - Open P0 action items with owners
  - "Ask questions about this incident in this channel."
- Output `channel-pins.md`: Separate sections (delimited by `---`) for pinnable messages:
  1. 📊 **Incident Summary** — Executive summary + impact metrics
  2. ⏱️ **Timeline** — Full chronological timeline with phases
  3. 🔍 **Root Cause** — 5 Whys chain + contributing factors
  4. ✅ **Action Items** — Full table with owners, priorities, due dates
  5. 💡 **Lessons Learned** — All lessons + reference to previous incident

---

## Phase 2: Integration (you do this)
1. Verify `index.html` contains ALL data from `channel-context.md` — every timestamp, every metric, every name, every action item
2. Cross-check numbers: 43 minutes, 12,000 requests, 3,400 users, 34% peak, 30% SLA budget
3. Verify timeline is in chronological order (03:12 → 03:14 → 03:16 → ... → 04:10)
4. Ensure action items are identical across report, channel-welcome, and channel-pins (same owners, same priorities, same due dates)
5. Embed all content directly — no external file dependencies

---

## Phase 3: Verification (spawn a NEW agent for this)

### Agent V — QA Verifier
**Task:** You are a QA engineer. You did NOT build this project. You have fresh eyes. Your job: open the output, try to break it, fix everything you find.

**Verify against the original incident log** (`./sample-data/incident-log.md`):
1. **Timestamp accuracy** — Every timestamp in the report matches the source log. Check all of them. The log starts at 03:12 and ends at 04:10.
2. **People accuracy** — Sarah Chen = SRE. Marcus Webb = DB Lead. Priya Sharma = Backend Lead. No name misspellings. No wrong role assignments.
3. **Metric accuracy** — 43-minute duration (03:12→03:55). ~12,000 failed requests. ~3,400 users. 34% peak error rate. 30% SLA budget. Verify each appears correctly.
4. **Timeline order** — Events are chronological. No events missing from the source log. Phase classifications are logical.
5. **JavaScript correctness** — No syntax errors. Timeline expand/collapse works. 5 Whys drill-down works. Table sorting works. Priority filter works.
6. **Print layout** — @media print: dark background removed, text readable in black, interactive elements hidden, clean page breaks.
7. **5 Whys logic** — The drill-down chain makes causal sense. Each "why" actually answers the previous level.
8. **Action items** — All 7 present. Each has: description, owner, priority, due date, status. None missing. Priorities make sense (P0s are the most urgent fixes).
9. **Cross-file consistency** — Same facts in `index.html`, `channel-context.md`, `channel-welcome.md`, and `channel-pins.md`. Pick 5 specific data points and verify across all files.
10. **Visual completeness** — SEV-1 badge renders. Color coding is consistent. SLA gauge visual works. Cards don't overflow. Timeline connecting line is continuous.

**Fix every issue you find.** Do not report — fix. This is a live demo in front of MIT.

---

## Phase 4: Channel Agent Deployment (orchestrator coordinates this AFTER verification passes)

**Important timing:** This phase creates a Mattermost channel and posts content. Do NOT run this phase until Phases 1-3 are complete and verified. The orchestrator should wait for explicit confirmation before proceeding, as this may require a gateway restart that could interrupt other running agent teams.

### Agent D — Channel Deployer
**Task:** Set up the live Mattermost postmortem channel.

1. **Create channel:** `#postmortem-2026-03-21` — Display name: "Postmortem: DB Connection Pool Exhaustion"
2. **Post welcome message:** Use the content from `channel-welcome.md` as the first message
3. **Post and pin each section** from `channel-pins.md`:
   - Post each pinned message (separated by `---` in the file) as individual messages
   - Pin each one after posting
4. **Set channel topic:** "🔴 SEV-1 RESOLVED — Database Connection Pool Exhaustion (2026-03-21)"
5. **Set channel purpose:** "AI-assisted incident postmortem. Ask questions about the timeline, root cause, action items, or related incidents."

The channel should be immediately usable — someone can join and ask "What was the root cause?" or "Who owns the P0 action items?" or "Has this happened before?" and get accurate answers from the incident analysis.

---

## Delivery
- `index.html` — Fully functional postmortem report, opens in any browser
- `channel-context.md` — Complete incident analysis for channel agent context
- `channel-welcome.md` — Ready to post as first channel message
- `channel-pins.md` — 5 messages ready to pin individually
- `#postmortem-2026-03-21` — Live Mattermost channel with posted content and agent context
