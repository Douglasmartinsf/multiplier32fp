# Compatibility entrypoint for existing shell sessions (this is Bash, not Tcl).
export PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "$PROJECT_DIR/scripts/environment.sh"
