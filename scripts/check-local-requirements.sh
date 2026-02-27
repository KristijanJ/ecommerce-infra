#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Symbols
CHECK="✓"
CROSS="✗"
WARN="⚠"

ERRORS=0
WARNINGS=0

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

pass() {
    echo -e "  ${GREEN}${CHECK} $1${NC}"
}

fail() {
    echo -e "  ${RED}${CROSS} $1${NC}"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo -e "  ${YELLOW}${WARN}  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

check_command() {
    local cmd="$1"
    local label="${2:-$1}"
    local hint="$3"

    if command -v "$cmd" &>/dev/null; then
        local version
        version=$("$cmd" version --short 2>/dev/null \
            || "$cmd" version 2>/dev/null \
            || "$cmd" --version 2>/dev/null \
            | head -1)
        pass "$label  =>  $(echo "$version" | head -1)"
    else
        fail "$label not found${hint:+ — $hint}"
    fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

echo -e "${BOLD}${CYAN}========================================${NC}"
echo -e "${BOLD}${CYAN}  Local Development Requirements Check${NC}"
echo -e "${BOLD}${CYAN}========================================${NC}\n"

# --- Required tools -----------------------------------------------------------
echo -e "${BOLD}Required tools:${NC}"

check_command docker    "Docker"   "https://docs.docker.com/get-docker/"

# --- Docker daemon ------------------------------------------------------------
echo -e "${BOLD}Docker daemon:${NC}"
if docker info &>/dev/null; then
    pass "Docker daemon is running"
else
    fail "Docker daemon is not running — start Docker Desktop or the Docker service"
fi

echo ""

# --- Summary ------------------------------------------------------------------
echo -e "${BOLD}${CYAN}========================================${NC}"
if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${BOLD}${GREEN}  All checks passed — ready to go!${NC}"
elif [ "$ERRORS" -eq 0 ]; then
    echo -e "${BOLD}${YELLOW}  ${WARNINGS} warning(s) — environment should work but review above${NC}"
else
    echo -e "${BOLD}${RED}  ${ERRORS} error(s), ${WARNINGS} warning(s) — fix errors before continuing${NC}"
fi
echo -e "${BOLD}${CYAN}========================================${NC}\n"

[ "$ERRORS" -eq 0 ]