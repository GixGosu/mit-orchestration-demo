# MIT GenAI Global — OpenClaw Live Demo

**Presented:** April 19, 2026 at MIT GenAI Global  
**Topic:** AI Agents as Engineers, Not Engines

Three products built live from scratch during the presentation using Claude Code's multi-agent orchestration. The agents build the thing, then get out of the way.

## Demos

### 1. NASA NEO Asteroid Dashboard
**[`demos/nasa-neo-dashboard/`](demos/nasa-neo-dashboard/index.html)** - open `index.html` in a browser

Animated orbital visualization of Near-Earth Objects using NASA's NEO Feed API.
- Real-time asteroid data with date range selector
- Parabolic approach trajectories, mission-control aesthetic
- Threat overview cards, sortable table, size comparison chart, timeline
- Works by double-clicking the HTML file

**Deterministic output.** No LLM in the runtime loop, real orbital data from NASA.

### 2. Employee Onboarding System
**[`demos/onboarding-system/`](demos/onboarding-system/index.html)** - open `index.html` in a browser

Interactive onboarding portal with department-specific checklists, policy references, and IT setup guides. Also generates Mattermost channel content for a live Q&A assistant.

**Nondeterministic runtime.** When deployed with a chat bridge, the LLM answers questions from onboarding docs.

During the live demo, this system also deployed a channel agent into Mattermost via [ChatBridge](https://github.com/GixGosu/chatbridge). The build agents generate `channel-context.md`, `channel-pins.md`, and `channel-welcome.md`, which get loaded as workspace context for a persistent chat agent that answers new-hire questions in real time. See [Deploying Channel Agents](#deploying-channel-agents) below.

### 3. Incident Postmortem System
**[`demos/postmortem-system/`](demos/postmortem-system/index.html)** - open `index.html` in a browser

Ingests a sample incident log, produces a structured postmortem report with timeline, root cause analysis, and action items. Generates Mattermost channel content for incident discussion.

**Nondeterministic runtime.** When deployed with a chat bridge, the LLM answers questions about the incident.

Same setup as onboarding. The build agents produce channel content files that power a live chat agent for async incident Q&A via [ChatBridge](https://github.com/GixGosu/chatbridge). See [Deploying Channel Agents](#deploying-channel-agents) below.

## Presentation Slides

- **[`presentation/slides.html`](presentation/slides.html)** - Main presentation: "AI Agents: Engineers, Not Engines"
- **[`presentation/slides-2.html`](presentation/slides-2.html)** - Addendum: "Platform Risk & What They Killed"

Open in a browser. Navigate with arrow keys or spacebar.

## Agent Prompts

- [`prompts/01-nasa-neo-dashboard.md`](prompts/01-nasa-neo-dashboard.md) - Data Architect + Visualization Engineer + QA Verifier
- [`prompts/02-onboarding-system.md`](prompts/02-onboarding-system.md) - Content Architect + Frontend Developer + Channel Formatter + QA Verifier
- [`prompts/03-postmortem-system.md`](prompts/03-postmortem-system.md) - Incident Analyst + Report Designer + Channel Formatter + QA Verifier

## How It Was Built

Each demo was built by launching a Claude Code instance with `--dangerously-skip-permissions`:

```bash
# All 3 run in parallel. See demo-launch.sh
claude --dangerously-skip-permissions -p "$(cat prompts/01-nasa-neo-dashboard.md)"
```

All three prompts use multi-agent orchestration. Each spawns specialized agents in parallel (data/content + frontend/visualization), integrates the outputs, then runs a QA verification agent. ~14 minutes per demo.

## Key Takeaways

The NASA dashboard has zero AI in its runtime. The onboarding and postmortem systems do. Know which one you're building.

Multi-agent builds fail silently without shared schemas between agents. Interface contracts are the difference between "it works" and "it works sometimes."

Platform risk is real. See `slides-2.html` for the honest take on vendor lock-in and API rug-pulls.

## Requirements

- A modern browser (Chrome, Firefox, Edge, Safari)
- No build steps, no npm install. Chart.js loads from CDN automatically.

### NASA API Key

The NASA dashboard ships with `DEMO_KEY`, which works but is rate-limited (30 req/hour per IP). To get your own:

1. Go to [https://api.nasa.gov/#signUp](https://api.nasa.gov/#signUp)
2. Sign up with your email (instant)
3. Open `demos/nasa-neo-dashboard/index.html` and replace `DEMO_KEY` on the `API_KEY` line with your key

Free, 1,000 req/hour.

## Deploying Channel Agents

The onboarding and postmortem demos each produce three channel content files alongside their HTML dashboards:

| File | Purpose |
|------|---------|
| `channel-context.md` | Full knowledge base, loaded as the agent's system prompt context |
| `channel-pins.md` | Key reference material, posted as pinned messages in the channel |
| `channel-welcome.md` | Welcome message posted when the channel is created |

To deploy these as live chat agents using [ChatBridge](https://github.com/GixGosu/chatbridge):

1. Set up ChatBridge for your platform (Mattermost, Discord, Slack, or Telegram)
2. Create a channel for the agent (e.g. `#onboarding-meridian`, `#postmortem-2026-03-21`)
3. Copy `channel-context.md` to your ChatBridge workspace's `channel-contexts/` directory, named to match the channel (e.g. `onboarding-meridian.md`)
4. Post the contents of `channel-welcome.md` and `channel-pins.md` into the channel
5. Add the channel ID to `allowed_channels` in your ChatBridge `config.json`

The agent answers questions in that channel using the generated knowledge base as context.

## What We Use Instead

The orchestration in this demo originally relied on OpenClaw, which got killed by upstream platform changes (see `slides-2.html`). We replaced it with **[ChatBridge](https://github.com/GixGosu/chatbridge)**: ~200 lines of shared core + ~100 per platform adapter. Mattermost, Discord, Slack, Telegram.

It spawns `claude` CLI as a subprocess, so you get full Claude Code tool access (bash, file I/O, etc.) with per-channel context, persistent sessions, and workspace memory. You own the orchestration layer. No vendor dependency beyond the model API.

This also cuts token usage substantially. OpenClaw's orchestration burned tokens on coordination overhead between agents. ChatBridge delegates that to subprocess calls and workspace files. The AI spends tokens on actual work instead of managing itself.

If the platform risk talk resonated, ChatBridge is how we practice what we preach.

---

Built by [Joshua Burdick](https://cyberarctica.com)

## License

MIT
