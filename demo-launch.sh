#!/bin/bash
# MIT Demo Launch Script — kicks off all 3 agent builds in parallel
# Run this during slide 4 ("Let's Build")
#
# Usage: cd into the repo root, then run ./demo-launch.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Launching 3 agent teams..."
echo ""

# Clear old outputs
rm -f "$SCRIPT_DIR/demos/nasa-neo-dashboard/index.html"
rm -f "$SCRIPT_DIR/demos/nasa-neo-dashboard/data-layer.js"
rm -f "$SCRIPT_DIR/demos/onboarding-system/index.html"
rm -f "$SCRIPT_DIR/demos/onboarding-system/channel-*.md"
rm -f "$SCRIPT_DIR/demos/postmortem-system/index.html"
rm -f "$SCRIPT_DIR/demos/postmortem-system/channel-*.md"

# NASA NEO Dashboard
(cd "$SCRIPT_DIR/demos/nasa-neo-dashboard" && \
claude --dangerously-skip-permissions -p "You are building a NASA Near-Earth Object dashboard with animated orbital visualization. Do ALL of the following work yourself — build every file, integrate them, then verify the result. Do not delegate or describe what you would do. Write code.

$(cat "$SCRIPT_DIR/prompts/01-nasa-neo-dashboard.md")

When completely finished, run: echo \"Done: NASA NEO Dashboard built\"") &
PID1=$!
echo "🌑 NASA Dashboard launched (PID $PID1)"

# Employee Onboarding
(cd "$SCRIPT_DIR/demos/onboarding-system" && \
claude --dangerously-skip-permissions -p "You are building an employee onboarding system. Do ALL of the following work yourself — build every file, integrate them, then verify the result. Do not delegate or describe what you would do. Write code.

$(cat "$SCRIPT_DIR/prompts/02-onboarding-system.md")

IMPORTANT: Skip Phase 4 (Channel Deployment) for now. Only complete Phases 1-3.

When completely finished, run: echo \"Done: Onboarding System built\"") &
PID2=$!
echo "👋 Onboarding System launched (PID $PID2)"

# Incident Postmortem
(cd "$SCRIPT_DIR/demos/postmortem-system" && \
claude --dangerously-skip-permissions -p "You are building an incident postmortem system. Do ALL of the following work yourself — build every file, integrate them, then verify the result. Do not delegate or describe what you would do. Write code.

$(cat "$SCRIPT_DIR/prompts/03-postmortem-system.md")

IMPORTANT: Skip Phase 4 (Channel Deployment) for now. Only complete Phases 1-3.

When completely finished, run: echo \"Done: Postmortem System built\"") &
PID3=$!
echo "🔴 Postmortem System launched (PID $PID3)"

echo ""
echo "All 3 agents running in parallel."
echo "You'll get notifications as each completes."
echo ""
echo "PIDs: NASA=$PID1  Onboarding=$PID2  Postmortem=$PID3"
