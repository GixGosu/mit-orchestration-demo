# Employee Onboarding System — Orchestration Task

You are the lead orchestrator for building an employee onboarding system. Your job is coordination: spawn agents, sequence phases, merge outputs. You do NOT do the building or verification yourself.

## Project Output Directory
`./demos/onboarding-system/` (relative to repo root)

## Context
Fictional company: **Meridian Labs** — a mid-size AI/ML company (~200 employees). Mission: "Making AI accessible to every industry."

---

## Phase 1: Parallel Build (spawn these simultaneously)

### Agent A — Content Architect
**Task:** Create the complete onboarding knowledge base. This is the single source of truth — all other agents consume your output.
- Output: `channel-context.md`

**Content to create:**
- **Company Overview:** Mission, 5 core values with descriptions, brief founding story, org structure (Engineering, Product, Design, Data Science, Sales, HR, Finance)
- **Day-by-Day Checklist (Week 1):** Detailed items with descriptions and estimated time for each:
  - Day 1: IT setup (laptop config, Slack/email/GitHub/Figma accounts, VPN, 2FA with 1Password), badge photo, 30-min meet-your-manager, office tour with buddy
  - Day 2: Engineering onboarding (clone repos, dev environment setup doc, CI/CD overview with GitHub Actions, coding standards walkthrough), complete security training (30 min)
  - Day 3: Product deep-dive (live product demo 1hr, roadmap walkthrough, 3 customer personas review), team lunch at noon
  - Day 4: First ticket assignment (starter bug or small feature), pair programming session (2hr), 30-min skip-level 1:1
  - Day 5: Attend all-hands (Fri 2 PM), write intro post in #introductions, 30-min first-week retro with manager
- **Team Directory (10 people):**
  1. Alex Rivera — CTO — "Ask me about: technical vision, architecture decisions" — @alex.r
  2. Jordan Kim — VP Engineering — "Ask me about: team structure, career growth" — @jordan.k
  3. Sam Patel — Engineering Manager — "Ask me about: sprint process, your first project" — @sam.p
  4. Maria Santos — Senior Backend Engineer — "Ask me about: API design, database patterns" — @maria.s
  5. Tyler Brooks — Senior Frontend Engineer — "Ask me about: React architecture, design system" — @tyler.b
  6. Aisha Okonkwo — Staff ML Engineer — "Ask me about: model training, data pipelines" — @aisha.o
  7. Chris Nguyen — Product Manager — "Ask me about: roadmap, feature prioritization" — @chris.n
  8. Dana Larson — Head of Design — "Ask me about: design system, user research" — @dana.l
  9. Robin Hayes — HR Business Partner — "Ask me about: benefits, PTO, onboarding" — @robin.h
  10. Casey Morgan — IT Support Lead — "Ask me about: laptop issues, access requests" — @casey.m
- **Key Resources by Category:**
  - IT & Access: VPN setup (vpn.meridian.dev), 1Password team vault, 2FA enrollment guide, laptop policy (Mac or Linux, your choice), wifi password process
  - Engineering: GitHub org (github.com/meridian-labs), docs (docs.meridian.dev), staging (staging.meridian.dev), CI/CD dashboard, PR review guidelines
  - HR & Benefits: PTO (unlimited, 15-day minimum encouraged), health/dental/vision (enrollment within 30 days of start), 401k (4% match, immediate vesting), equity (4-year vest, 1-year cliff), learning budget ($2,000/year)
  - Culture: Slack channels (#general, #random, #shipped — share launches, #til — today I learned, #pets, #food, #fitness), ERGs (Women in Tech, LGBTQ+, Parents, BIPOC), monthly game night (first Thursday), quarterly offsite
- **FAQ (18 questions):** Parking (garage B, badge access), dress code (casual, no policy), remote work (3 days in-office Tue/Wed/Thu, flexible on Mon/Fri), expense reports (Expensify, manager approval >$100), learning budget (books, courses, conferences — just get manager OK), laptop refresh (every 3 years), relocation support (ask HR), referral bonus ($5,000), performance reviews (biannual, March and September), promotion process, on-call rotation (after 3 months), meeting-free Fridays (encouraged), lunch options (cafeteria + food trucks Tue/Thu), guest wifi (meridian-guest, no password), shipping merch to remote (Slack #swag), mental health (free Headspace + 6 EAP sessions/year), commuter benefits ($150/month pre-tax), and sabbatical (4 weeks paid after 5 years)

### Agent B — Frontend Developer
**Task:** Build the onboarding portal UI as a single HTML file.
- **Important:** Get content from Agent A's `channel-context.md`. All text must match exactly — no making up different content.
- **Welcome Section:** Animated fade-in greeting ("Welcome to Meridian Labs!"), company logo placeholder (styled initials "ML" in a circle), mission statement, warm 2-sentence welcome
- **Progress Tracker:** Fixed bar at top of page. Visual progress bar with percentage. Updates live as checkboxes are toggled.
- **Day-by-Day View:** 5 tabs (Day 1–5) or accordion. Each item: checkbox (persists via localStorage), title, description, estimated time badge. Checked items get strikethrough + green checkmark.
- **Team Directory:** Responsive card grid (2-3 columns). Each card: initials avatar (colored circle, color derived from name), name, role, "Ask me about..." on hover tooltip, Slack handle.
- **Resources:** 4-category card layout with section icons (🔧 IT, 💻 Engineering, 👥 HR, 🎯 Culture). Each resource: name, brief description, link. Search bar filters across all categories.
- **FAQ:** Searchable accordion. Real-time filter as you type. Smooth expand/collapse animation. Shows result count. Empty state: "No matching questions found."
- **Completion Celebration:** At 100% checkbox completion: confetti canvas animation + congratulations modal with "You're officially onboarded!" message.
- **Design:** Light theme. Primary: #0066CC (blue), Secondary: #00B4D8 (teal), Accent: #06D6A0 (green for completion). White backgrounds, subtle #f0f2f5 section backgrounds. System font stack. Card shadows (0 2px 8px rgba). Hover lift on cards. Mobile responsive (stacks to single column below 768px). No external CSS frameworks.
- Output: `index.html`

### Agent C — Channel Content Formatter
**Task:** Create ready-to-post Mattermost channel content.
- Consume Agent A's `channel-context.md`
- Output `channel-welcome.md`: The first message for #onboarding. Warm, organized. Explains what the channel is for ("Ask any onboarding question here — I have context on everything from IT setup to benefits to team intros"). Lists what you can ask about. Ends with an encouraging note.
- Output `channel-pins.md`: Separate sections (delimited by `---`) for individual pinnable messages:
  1. 📋 Day 1 Checklist — full Day 1 items with details
  2. 🔧 IT Setup Guide — VPN, accounts, 2FA, laptop
  3. 👥 Your Team — directory with "ask me about" for each person
  4. 💰 Benefits Quick Reference — enrollment deadlines, key numbers (401k match, PTO, learning budget)
  5. ❓ Top 5 FAQs — the most commonly asked first-week questions

---

## Phase 2: Integration (you do this)
1. Verify `index.html` uses ALL content from `channel-context.md` — check every FAQ, every team member, every resource link
2. Ensure names, numbers, policies are identical across all files
3. Embed content directly in HTML — no external file loading

---

## Phase 3: Verification (spawn a NEW agent for this)

### Agent V — QA Verifier
**Task:** You are a QA engineer. You did NOT build this project. Review everything with fresh eyes.

**Check `index.html`:**
1. **Content completeness** — Count: all 10 team members present? All 18 FAQs? All 5 days with all items? All resource categories populated? No "lorem ipsum" or placeholder text anywhere.
2. **localStorage** — Check: checkboxes save state. Reload should preserve checked items. Clear localStorage and verify clean start.
3. **Progress bar** — Manually trace the calculation: if 3 of 25 items checked, bar should show 12%. Verify the total item count is correct.
4. **Search** — FAQ search: type "parking" → only parking FAQ shows. Type "zzzzz" → empty state message. Clear search → all FAQs return. Resource search: same behavior.
5. **Tabs/Accordion** — Click each day tab → correct content shows. No content from other days leaking through.
6. **Team cards** — All 10 render. Initials are correct (Alex Rivera = AR). Colors are consistent per person. Hover tooltip shows "Ask me about..." text.
7. **Confetti** — Check all boxes programmatically (or trace the logic) — does confetti trigger at exactly 100%? Does it trigger again on reload if already at 100%?
8. **Responsive** — Below 768px: single column layout, cards stack, table scrolls, nothing overflows viewport.
9. **Cross-file consistency** — Pick 5 random facts from `channel-context.md` (a policy, a name, a Slack channel, a number, a deadline). Verify they appear identically in `index.html`, `channel-welcome.md`, and `channel-pins.md`.

**Fix every issue you find.** This is a live demo in front of MIT.

---

## Phase 4: Channel Agent Deployment (orchestrator coordinates this AFTER verification passes)

**Important timing:** This phase creates a Mattermost channel and posts content. Do NOT run this phase until Phases 1-3 are complete and verified. The orchestrator should wait for explicit confirmation before proceeding, as this may require a gateway restart that could interrupt other running agent teams.

### Agent D — Channel Deployer
**Task:** Set up the live Mattermost channel for the onboarding agent.

1. **Create channel:** `#onboarding-meridian` — Display name: "Meridian Labs Onboarding"
2. **Post welcome message:** Use the content from `channel-welcome.md` as the first message
3. **Post and pin each section** from `channel-pins.md`:
   - Post each pinned message (separated by `---` in the file) as individual messages
   - Pin each one after posting
4. **Set channel topic:** "🎉 New hire onboarding — ask me anything about Meridian Labs"
5. **Set channel purpose:** "AI-powered onboarding assistant with full knowledge of Meridian Labs policies, team directory, and Day 1-5 checklist."

The channel should be immediately usable — someone can join and ask questions like "What's on my Day 3 checklist?" or "Who should I ask about API design?" and get accurate answers from the channel context.

---

## Delivery
- `index.html` — Fully functional, opens in any browser
- `channel-context.md` — Complete knowledge base for channel agent
- `channel-welcome.md` — Ready to post as first channel message
- `channel-pins.md` — 5 messages ready to pin individually
- `#onboarding-meridian` — Live Mattermost channel with posted content and agent context
