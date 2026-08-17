#!/bin/bash
set -euo pipefail

# === CTF Challenge Creator Skill Installer ===
# Install from GitHub repo for Codex and Claude Code
# Usage: bash install.sh

SKILL_NAME="ctf-challenge-creator"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
CODEX_DIR="${CODEX_HOME:-${HOME}/.codex}"
HAS_CODEX=false
HAS_CLAUDE=false

command -v codex &>/dev/null && HAS_CODEX=true
command -v claude &>/dev/null && HAS_CLAUDE=true

if [ "${HAS_CODEX}" = false ] && [ "${HAS_CLAUDE}" = false ]; then
    echo "ERROR: Neither Codex nor Claude Code was detected in PATH."
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  CTF Challenge Creator Skill Installer  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# === Step 1: Verify Docker ===
echo "[1/6] Checking Docker..."
if command -v docker &>/dev/null; then
    echo "  Docker: $(docker --version)"
else
    echo "  WARNING: Docker not found. Docker-based challenge testing will not work."
    echo "  Install Docker from https://docs.docker.com/get-docker/"
fi

# === Step 2: Verify Docker Compose ===
echo "[2/6] Checking Docker Compose..."
if docker compose version &>/dev/null; then
    echo "  Docker Compose: available"
else
    echo "  WARNING: docker compose not found."
fi

# === Step 3: Create directories ===
echo "[3/6] Creating directories..."
[ "${HAS_CODEX}" = true ] && mkdir -p "${CODEX_DIR}/skills"
if [ "${HAS_CLAUDE}" = true ]; then
    mkdir -p "${CLAUDE_DIR}/skills"
    mkdir -p "${CLAUDE_DIR}/agents"
fi
echo "  Directories ready"

# === Step 4: Install skill files ===
echo "[4/6] Installing skill links..."
rm -rf "${HOME}/.agents/skills/${SKILL_NAME}"
if [ "${HAS_CODEX}" = true ]; then
    rm -rf "${CODEX_DIR}/skills/${SKILL_NAME}"
    ln -s "${REPO_DIR}" "${CODEX_DIR}/skills/${SKILL_NAME}"
fi
if [ "${HAS_CLAUDE}" = true ]; then
    rm -rf "${CLAUDE_DIR}/skills/${SKILL_NAME}"
    ln -s "${REPO_DIR}" "${CLAUDE_DIR}/skills/${SKILL_NAME}"
fi

echo "  Skill files installed"

# === Step 5: Install agent ===
echo "[5/6] Installing agent definition..."
if [ "${HAS_CLAUDE}" = true ]; then
    for agent_file in "${REPO_DIR}/agents/"*.md; do
        if [ -f "$agent_file" ]; then
            agent_name=$(basename "$agent_file")
            cp "$agent_file" "${CLAUDE_DIR}/agents/${agent_name}"
            echo "  Agent: ${agent_name}"
        fi
    done
else
    echo "  Claude Code not detected; skipped"
fi
echo "  Agent definitions installed"

# === Step 6: Verify ===
echo "[6/6] Verifying installation..."
ERRORS=0

if [ "${HAS_CODEX}" = true ]; then
    if [ -L "${CODEX_DIR}/skills/${SKILL_NAME}" ]; then
        echo "  Codex skill symlink: OK"
    else
        echo "  Codex skill symlink: MISSING"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ "${HAS_CLAUDE}" = true ]; then
    if [ -L "${CLAUDE_DIR}/skills/${SKILL_NAME}" ]; then
        echo "  Claude skill symlink: OK"
    else
        echo "  Claude skill symlink: MISSING"
        ERRORS=$((ERRORS + 1))
    fi
    if [ -f "${CLAUDE_DIR}/agents/ctf-reviewer.md" ]; then
        echo "  ctf-reviewer agent: OK"
    else
        echo "  ctf-reviewer agent: MISSING"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "╔═══════════════════════════════╗"
    echo "║  Installation Successful!   ║"
    echo "╚═══════════════════════════════╝"
    echo ""
    echo "Installed components:"
    echo "  Source:  ${REPO_DIR}"
    [ "${HAS_CODEX}" = true ] && echo "  Codex:   ${CODEX_DIR}/skills/${SKILL_NAME}/ (symlink)"
    [ "${HAS_CLAUDE}" = true ] && echo "  Claude:  ${CLAUDE_DIR}/skills/${SKILL_NAME}/ (symlink)"
    [ "${HAS_CLAUDE}" = true ] && echo "  Agent:   ctf-reviewer"
    echo "  Templates: ${REPO_DIR}/templates/"
    echo ""
    [ "${HAS_CODEX}" = true ] && echo 'Codex usage:  $ctf-challenge-creator Create a Web SSTI Easy challenge'
    [ "${HAS_CLAUDE}" = true ] && echo 'Claude usage: /ctf-challenge-creator Create a Web SSTI Easy challenge'
    echo ""
    echo "To uninstall:"
    echo "  rm ${CODEX_DIR}/skills/${SKILL_NAME}"
    echo "  rm ${CLAUDE_DIR}/skills/${SKILL_NAME}"
    echo "  rm ${CLAUDE_DIR}/agents/ctf-reviewer.md"
else
    echo "Installation completed with ${ERRORS} error(s)."
    echo "Please check the output above and retry."
    exit 1
fi
