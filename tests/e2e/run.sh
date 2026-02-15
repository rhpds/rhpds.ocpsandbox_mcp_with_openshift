#!/bin/bash
# End-to-end test runner for MCP with OpenShift sandbox migration
#
# Credentials: set env vars or use a local secrets.yml file (gitignored)
#   export GUID=xxxxx
#   export CLUSTER_ADMIN_TOKEN=eyJhbG...
#   export LITELLM_MASTER_KEY=sk-...
#
# Usage:
#   ./run.sh provision     # Deploy everything
#   ./run.sh destroy       # Tear down everything
#   ./run.sh provision -v  # Verbose
#   ./run.sh destroy -vv   # Extra verbose
#   ./run.sh provision -e @tests/e2e/secrets.yml  # Use local secrets file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

ACTION="${1:-provision}"
shift || true

export ANSIBLE_COLLECTIONS_PATH="$HOME/work/code/ansible_collections:$HOME/.ansible/collections"
export ANSIBLE_ROLES_PATH="$HOME/work/code/agnosticd-v2/ansible/roles"

PLAYBOOK="$SCRIPT_DIR/${ACTION}.yml"

if [[ ! -f "$PLAYBOOK" ]]; then
    echo "Error: Unknown action '$ACTION'. Use 'provision' or 'destroy'."
    exit 1
fi

echo "Running: $ACTION"
echo "Playbook: $PLAYBOOK"
echo "Collections: $ANSIBLE_COLLECTIONS_PATH"
echo ""

cd "$REPO_DIR"
~/work/ansible-for-me/bin/ansible-playbook "$PLAYBOOK" "$@"
