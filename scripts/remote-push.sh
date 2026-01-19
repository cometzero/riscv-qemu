#!/bin/bash
#
# remote-push.sh - Push all submodules and top-level repo to remote
#
# Usage: ./scripts/remote-push.sh [--force]
#
# Options:
#   --force    Use --force-with-lease for all push operations
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Parse arguments
FORCE_FLAG=""
if [[ "$1" == "--force" ]]; then
    FORCE_FLAG="--force-with-lease"
    echo "Force push mode enabled (--force-with-lease)"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Result tracking
declare -A RESULTS

push_repo() {
    local path="$1"
    local name="$2"

    cd "$path"

    # Check if on a branch
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
    if [[ -z "$branch" ]]; then
        RESULTS["$name"]="SKIPPED|detached HEAD"
        return
    fi

    # Check if remote exists
    if ! git remote get-url origin &>/dev/null; then
        RESULTS["$name"]="SKIPPED|no remote"
        return
    fi

    # Push
    if git push origin "$branch" $FORCE_FLAG 2>&1; then
        RESULTS["$name"]="SUCCESS|$branch"
    else
        RESULTS["$name"]="FAILED|$branch"
    fi
}

echo "=========================================="
echo "Remote Push - Submodules & Top-level Repo"
echo "=========================================="
echo ""

# Get submodules
cd "$PROJECT_ROOT"
SUBMODULES=$(git config --file .gitmodules --get-regexp path | awk '{ print $2 }')

# Push each submodule
for submodule in $SUBMODULES; do
    if [[ -d "$PROJECT_ROOT/$submodule" ]]; then
        echo -n "Pushing $submodule... "
        push_repo "$PROJECT_ROOT/$submodule" "$submodule"

        # Print result
        IFS='|' read -r status detail <<< "${RESULTS[$submodule]}"
        case "$status" in
            SUCCESS) echo -e "${GREEN}SUCCESS${NC} ($detail)" ;;
            FAILED)  echo -e "${RED}FAILED${NC} ($detail)" ;;
            SKIPPED) echo -e "${YELLOW}SKIPPED${NC} ($detail)" ;;
        esac
    fi
done

# Push top-level repo
echo -n "Pushing (top-level)... "
push_repo "$PROJECT_ROOT" "(top-level)"
IFS='|' read -r status detail <<< "${RESULTS[(top-level)]}"
case "$status" in
    SUCCESS) echo -e "${GREEN}SUCCESS${NC} ($detail)" ;;
    FAILED)  echo -e "${RED}FAILED${NC} ($detail)" ;;
    SKIPPED) echo -e "${YELLOW}SKIPPED${NC} ($detail)" ;;
esac

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
printf "%-25s %-10s %s\n" "Repository" "Status" "Branch"
echo "------------------------------------------"
for repo in "${!RESULTS[@]}"; do
    IFS='|' read -r status detail <<< "${RESULTS[$repo]}"
    case "$status" in
        SUCCESS) status_color="${GREEN}SUCCESS${NC}" ;;
        FAILED)  status_color="${RED}FAILED${NC}" ;;
        SKIPPED) status_color="${YELLOW}SKIPPED${NC}" ;;
    esac
    printf "%-25s ${status_color} %s\n" "$repo" "$detail"
done

echo ""
