# NASA NEO Asteroid Dashboard — Orchestration Task

You are the lead orchestrator for building a NASA Near-Earth Object dashboard with animated orbital visualization. Your job is coordination: spawn agents, sequence phases, merge outputs. You do NOT do the building or verification yourself.

## Project Output Directory
`./demos/nasa-neo-dashboard/` (relative to repo root)

---

## Critical Implementation Notes (ALL AGENTS must follow these)

These are hard-won lessons from prior builds. Violating any of these will produce a broken dashboard.

### NASA API Date Format
The NASA NEO API returns `close_approach_date_full` in the format `"2026-Apr-18 09:30"` (month abbreviation, not numeric). **Do NOT do `.replace(' ', 'T')` on this string** — it produces an unparseable ISO-like string. Instead use `new Date(close_approach_date_full)` directly, which browsers parse correctly. Always validate with `isNaN()` and fall back to the date-only field if parsing fails. Store the parsed millisecond timestamp (`_approachMs`) and use it everywhere instead of re-parsing date strings.

### Interface Contract: Data Layer → Visualization
The data layer must output objects with these exact fields. The visualization must consume these exact fields. No renaming, no re-parsing.
```
{
  id: String,
  name: String,
  estimated_diameter_min_m: Number,
  estimated_diameter_max_m: Number,
  is_potentially_hazardous: Boolean,
  close_approach_date: String,        // "YYYY-MM-DD" (date only, for display)
  close_approach_date_full: String,    // original NASA string (for reference)
  miss_distance_km: Number,
  miss_distance_lunar: Number,
  relative_velocity_kmh: Number,
  absolute_magnitude: Number,
  nasa_jpl_url: String,
  _approachMs: Number,                // PARSED millisecond timestamp — use this for all time math
}
```
The visualization must NEVER call `new Date()` on a date string from this data. Use `_approachMs` for all time calculations and construct display strings from it via `new Date(_approachMs).toISOString()`.

### Angular Distribution
Each asteroid's position angle around Earth must use `_approachMs` (full datetime including hours/minutes), not just the date. Using only the date causes all same-day asteroids to stack at the same angle. Additionally, add a velocity-based angular offset to spread asteroids that share similar approach times:
```js
const offset = Math.sin(velocity_kmh * 0.0001 + miss_distance_lunar * 7.3) * 0.4;
const angle = baseAngle + offset;
```

### Dynamic Scale
Miss distances in the data range from <1 LD to 200+ LD (80+ million km). Do NOT hardcode a max lunar distance. After loading data, compute `MAX_LD` from the actual maximum miss distance + 15% padding. Use a logarithmic scale (`log(ld+1) / log(MAX_LD+1)`) so close objects are spread out and distant ones don't all bunch at the edge. Orbit ring labels should adapt to the data range.

### Asteroid Movement Model
Use a parabolic approach model: each asteroid starts far, moves inward to its closest point at approach time, then recedes:
```js
const timeDelta = (currentTime - _approachMs) / windowMs;
const distanceFactor = 1 + Math.abs(timeDelta) * 2;
const currentLD = miss_distance_lunar * Math.min(distanceFactor, 1.5);
const currentAngle = baseAngle + timeDelta * 0.3; // angular drift during passage
```

---

## Phase 1: Parallel Build (spawn these simultaneously)

### Agent A — Data Architect
**Task:** Build the API integration layer as a standalone JavaScript module section.
- Target API: `https://api.nasa.gov/neo/rest/v1/feed`
- API Key: Use `DEMO_KEY` (rate-limited) or get a free key at https://api.nasa.gov/#signUp
- Implement: fetch wrapper with timeout (30s) and error handling, date range parameter support (max 7 days per API constraint), response parsing/transformation, loading state management
- Accept optional start/end date parameters; default to today + 6 days
- Transform raw API data into the **exact structure defined in the Interface Contract above**. Do not deviate from those field names.
- **CRITICAL:** Parse `close_approach_date_full` with `new Date()` directly. Do NOT use `.replace(' ', 'T')`. Store result as `_approachMs`. Validate with `isNaN()`, fall back to date-only field.
- Provide a `getSummaryStats()` method returning: totalCount, hazardousCount, closestApproach (name + distances), fastestObject (name + velocity)
- Provide a `getDateRange()` method returning `{ start: "YYYY-MM-DD", end: "YYYY-MM-DD" }`
- Handle: API errors (rate limit, network failure), empty responses, malformed data
- Output: `data-layer.js` (will be merged into final HTML as an inline `<script>`)

### Agent B — Visualization Engineer
**Task:** Build the complete UI as a single HTML file with embedded CSS and JS. This is a NASA mission control aesthetic — not a data table with a chart. The centerpiece is an animated orbital visualization.

**IMPORTANT:** Your code must consume data objects matching the **Interface Contract** defined in the Critical Notes above. Use `_approachMs` for all time calculations. Never call `new Date()` on string date fields from the data.

#### Date Range Selector (top of page)
- Two `<input type="date">` fields (start and end) + a "SCAN" button
- Default: today + 6 days
- Enforce 7-day max (NASA API constraint) — show error message if exceeded
- On fetch: call data layer with new dates, reset visualization state (trails, selection, playback), reload all dashboard sections
- Dark theme styling, monospace font, `color-scheme: dark`

#### Animated Orbital Visualization (CENTERPIECE — top 60% of viewport)
Full-width canvas element, dark space background. This is the hero.

**Scene setup:**
- Black background (#0a0e17) with subtle star field: 250 stars with viewport wrapping (generate coordinates up to 2000x2000, render with `x % canvasWidth`). 30% of stars should twinkle using `sin(time / 500 + phase)`. Sizes 0.5–2px.
- **Earth at center** — multi-layer rendering:
  - Atmospheric glow: radial gradient from `rgba(100,200,255,0.3)` to transparent, radius = earthRadius * 2
  - Body: 3-stop radial gradient with offset light source (CX-5, CY-5): `#4da6ff` → `#2d7dd2` → `#1a5490`
  - Specular highlight: small `rgba(255,255,255,0.3)` circle offset upper-left, radius = earthRadius * 0.3
  - "EARTH" label below in bold 10px sans-serif
- **Orbit rings** — dynamic based on data range:
  - Moon's Orbit (1 LD): **solid line**, bright (`rgba(100,200,255,0.4)`), lineWidth 2
  - Other rings (5, 20, 50, 100, 200 LD as appropriate): dashed, dimmer. Only show rings that fit within `MAX_LD`.
  - Labels in **Courier New 10px**
- Canvas must handle `devicePixelRatio` for retina displays

**Asteroid rendering:**
- Position: use `_approachMs` to compute angle via `(_approachMs - windowStart) / windowMs * 2π`, plus velocity offset (see Critical Notes). Radial distance from `ldToPixel()` using **dynamic** log scale with `MAX_LD` computed from data.
- Size: proportional to estimated diameter. Min 3px, max 20px. Log scale.
- **Body: radial gradient** with offset highlight for 3D depth:
  - Hazardous: `#ffaa77` → `#cc4422`
  - Safe: `#66ddff` → `#0088aa`
- Hazardous glow: pulsing radial gradient (`sin(time/200) * 0.3 + 0.7`), orange, 2.5x asteroid radius
- On hover: tooltip with name, diameter, miss distance, velocity, hazard status
- On click: select asteroid → highlight ring, show detail panel

**Animation — Time Lapse:**
- Time slider at bottom: scrub through the date range
- Play/pause button: adjustable speed (1x, 5x, 10x, 50x)
- Asteroids move along parabolic approach trajectories (see Critical Notes for movement model)
- **Trail effect:** line-segment trails, last **15** positions. Color: hazardous = `rgb(255,107,53)`, safe = `rgb(0,212,255)`. Opacity fades 0→0.5. Draw trails BEFORE asteroids (behind). Clear on scrub and wrap-around.
- Closest approach (progress > 0.95): white expanding flash. If hazardous + inside 1 LD: red flash on Moon orbit ring.
- Current date/time in monospace
- Labels: Courier New 9px, centered above asteroid, only for hazardous or selected (reduces clutter)

**Controls overlay (bottom, semi-transparent dark bar with backdrop blur):**
- Play/Pause (▶/⏸), Speed selector (1x|5x|10x|50x), Time scrubber, Timestamp display
- Toggle buttons: Safe asteroids, Trails, Labels

#### Dashboard Below Visualization
- **Threat Overview Cards:** Total objects, hazardous count (orange glow if >0), closest approach (name + LD), fastest (name + velocity). Monospace numbers.
- **Detail Panel:** Selected asteroid full stats: name, diameter range, miss distance (km, miles, LD), velocity, magnitude, approach date, hazard assessment, NASA JPL link. Close button.
- **Interactive Table:** All NEOs, sortable by every column. Hazardous rows highlighted. Click row → selects asteroid + scrolls to viz. Sort arrows in headers.
- **Size Comparison:** Horizontal bars, top 10 by diameter. Reference lines: car (~4m), house (~10m), Statue of Liberty (~93m), football field (~109m).
- **Close Approach Timeline:** Chart.js bubble chart via CDN. X = time, Y = miss distance in LD (reversed), size from diameter. Hazardous orange, safe cyan. Click selects asteroid.

#### Design
- Dark background (#0a0e17), panels (#111827), accent (#00d4ff), hazard (#ff6b35), text (#e2e8f0)
- Monospace for data, sans-serif for labels
- 60fps via requestAnimationFrame
- Loading: "ACQUIRING SIGNAL..." with blinking cursor. Error: "SIGNAL LOST" banner. Empty: "NO OBJECTS DETECTED"
- Responsive: cards 4→2→1 col, table scrolls, canvas scales
- No external CSS frameworks. Chart.js CDN for timeline only.
- Output: `index.html`

---

## Phase 2: Integration (you do this)
After both agents complete:
1. Merge `data-layer.js` into `index.html` — the data layer code goes into a `<script>` section in `<head>`
2. Wire up: data layer feeds data to visualization, table, cards, timeline
3. **Verify the Interface Contract:** every field the visualization reads must match what the data layer outputs. Check field names character by character.
4. **Verify date handling:** grep for `new Date(` in the visualization code — it should ONLY appear with `_approachMs` or `.toISOString()` for display. Never with a raw date string from the data.
5. **Verify scale:** confirm `MAX_LD` is computed from actual data, not hardcoded
6. Verify Chart.js CDN link is present if used
7. Save the merged result as the final `index.html`

---

## Phase 3: Verification (spawn a NEW agent for this)

### Agent V — QA Verifier
**Task:** You are a QA engineer. You did NOT build this project. Open the output with fresh eyes, break it, fix it.

**Review the final `index.html` and check:**
1. **Console errors** — Open the file conceptually and trace the code. Look for ANY `new Date()` call on a string that could produce "Invalid time value". Look for ANY canvas operation that could receive NaN or Infinity (createRadialGradient, arc). These are the #1 source of bugs.
2. **API integration** — Does the fetch call work? Is the URL correct? Is the API key present? Test with a curl command to verify the API returns data for today's date range.
3. **Asteroid distribution** — Trace `dateToAngle()` and the velocity offset. Confirm asteroids will NOT all cluster at 7 positions (one per day). They must spread around the full circle using the full datetime.
4. **Scale** — Confirm `MAX_LD` is computed from data, not hardcoded. Confirm `ldToPixel` uses `MAX_LD`. An asteroid at 200 LD should be visible within the visualization, not at the edge.
5. **Interface contract** — Verify data layer output fields match what the visualization consumes. Check every field name.
6. **Orbital visualization** — Earth has glow + gradient + specular highlight? Stars twinkle? Orbit rings labeled in Courier New? Moon orbit solid and brighter than others?
7. **Interaction sync** — Click asteroid → detail panel + table row. Click table row → viz scroll + select. Tooltip on hover.
8. **Playback** — Play/pause works. Speed selector works. Trails render as line segments (not dots), 15 positions. Trails clear on scrub.
9. **Date selector** — Two date inputs + SCAN button present. 7-day max enforced. Changing dates reloads data.
10. **Error/loading states** — "ACQUIRING SIGNAL..." on load. "SIGNAL LOST" on error. "NO OBJECTS DETECTED" on empty.

**Fix every issue you find.** Do not just report — fix. The output must work flawlessly on first open in a browser. This is a live demo in front of an MIT audience — the visualization is the centerpiece.

---

## Delivery
Final output: single `index.html` file in `./demos/nasa-neo-dashboard/` that works by double-clicking in any modern browser. No build steps, no dependencies beyond Chart.js CDN (if used).
