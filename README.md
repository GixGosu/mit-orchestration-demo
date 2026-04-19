# MIT GenAI Global — OpenClaw Live Demo

**Presented:** April 19, 2026 at MIT GenAI Global  
**Topic:** AI Agents as Engineers, Not Engines

Three products built live from scratch during the presentation using Claude Code's multi-agent orchestration — demonstrating AI agents as builders, not runtime dependencies.

## Demos

### 1. NASA NEO Asteroid Dashboard
**[`demos/nasa-neo-dashboard/`](demos/nasa-neo-dashboard/index.html)** — Open `index.html` in a browser

An animated orbital visualization of Near-Earth Objects using NASA's NEO Feed API. Features:
- Real-time asteroid data with date range selector
- Animated orbital visualization with parabolic approach trajectories
- Mission-control aesthetic with Earth rendering, star field, orbit rings
- Threat overview cards, sortable table, size comparison chart, timeline
- No build steps — works by double-clicking the HTML file

**Deterministic output** — no LLM in the runtime loop, real orbital data from NASA.

### 2. Employee Onboarding System
**[`demos/onboarding-system/`](demos/onboarding-system/index.html)** — Open `index.html` in a browser

An interactive onboarding portal with department-specific checklists, policy references, and IT setup guides. Also generates Mattermost channel content for a live Q&A assistant.

**Nondeterministic runtime** — when deployed with a chat bridge, the LLM answers questions from onboarding docs.

### 3. Incident Postmortem System
**[`demos/postmortem-system/`](demos/postmortem-system/index.html)** — Open `index.html` in a browser

Ingests a sample incident log, produces a structured postmortem report with timeline, root cause analysis, and action items. Generates Mattermost channel content for incident discussion.

**Nondeterministic runtime** — when deployed with a chat bridge, the LLM answers questions about the incident.

## Presentation Slides

- **[`presentation/slides.html`](presentation/slides.html)** — Main presentation: "AI Agents — Engineers, Not Engines"
- **[`presentation/slides-2.html`](presentation/slides-2.html)** — Addendum: "Platform Risk & What They Killed"

Open in a browser. Navigate with arrow keys or spacebar.

## Agent Prompts

The exact prompts used to build each demo:

- [`prompts/01-nasa-neo-dashboard.md`](prompts/01-nasa-neo-dashboard.md) — (Data Architect + Visualization Engineer + QA Verifier)
- [`prompts/02-onboarding-system.md`](prompts/02-onboarding-system.md) — (Content Architect + Frontend Developer + Channel Formatter + QA Verifier)
- [`prompts/03-postmortem-system.md`](prompts/03-postmortem-system.md) — (Incident Analyst + Report Designer + Channel Formatter + QA Verifier)

## How It Was Built

Each demo was built by launching a Claude Code instance with `--dangerously-skip-permissions`:

```bash
# All 3 run in parallel — see demo-launch.sh
claude --dangerously-skip-permissions -p "$(cat prompts/01-nasa-neo-dashboard.md)"
```

The NASA prompt uses a multi-agent architecture: Agent A (data layer), Agent B (visualization), then integration and Agent V (QA verification). Total build time target: ~14 minutes per demo.

## Key Takeaways

- **AI as engineer, not engine**: The agent builds the artifact, then gets out of the way. The NASA dashboard has zero AI in its runtime.
- **Deterministic vs nondeterministic**: Know when your output needs an LLM at runtime and when it doesn't.
- **Interface contracts matter**: Multi-agent builds fail silently without shared schemas between agents.
- **Platform risk is real**: See `slides-2.html` for the honest take on vendor lock-in and API rug-pulls.

## Requirements

- A modern browser (Chrome, Firefox, Edge, Safari)
- No build steps, no npm install, no dependencies beyond Chart.js CDN (loaded automatically)

### NASA API Key

The NASA dashboard ships with `DEMO_KEY`, which works but is rate-limited (30 requests/hour per IP). For reliable use:

1. Go to [https://api.nasa.gov/#signUp](https://api.nasa.gov/#signUp)
2. Sign up with your email — you'll get a key instantly
3. Open `demos/nasa-neo-dashboard/index.html` and replace `DEMO_KEY` on the `API_KEY` line with your key

The key is free with a 1,000 requests/hour limit — more than enough for demos.

## What We Use Instead

The orchestration in this demo originally relied on OpenClaw, which was killed by upstream platform changes and required additional custom modifications to run (see `slides-2.html`). We now use **[ChatBridge](https://github.com/GixGosu/chatbridge)** — minimal chat platform bridges for Claude Code that let you run persistent AI agents in Mattermost, Discord, Slack, or Telegram.

- ~200 lines of shared core + ~100 lines per platform adapter
- Per-channel context, persistent sessions, workspace memory
- You own the orchestration layer — no vendor dependency beyond the model API
- Spawns `claude` CLI as a subprocess, so you get full Claude Code tool access (bash, file I/O, etc.)

This approach also cuts token usage substantially — OpenClaw's orchestration layer burned tokens on coordination overhead between agents, while ChatBridge delegates that to simple subprocess calls and workspace files. The AI spends tokens on actual work, not on managing itself.

If the talk about platform risk resonated, ChatBridge is how we practice what we preach.

## License

MIT
