#!/usr/bin/env bash
# apothecary.sh - menu CLI or classic engine passthrough
ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$(realpath "$ROOT")"
APO_CLI="$(realpath "$ROOT/scripts/apo.sh")"
APOTHECARY_BIN="$(realpath "$ROOT/apothecary/apothecary")"

if [[ $# -eq 0 ]] || [[ "${1:-}" =~ ^(menu|demo|platforms|formulas|libs|status|version|help|-h|--help|update|download|build|copy|clean|remove|remove-all|remove-lib|framework)$ ]]; then
	if [[ -f "$APO_CLI" ]]; then
		. "$APO_CLI" "$@"
		exit $?
	fi
fi

if [[ ! -f "$APOTHECARY_BIN" ]]; then
	echo "Error: apothecary not found at ${APOTHECARY_BIN}" >&2
	exit 1
fi

. "$APOTHECARY_BIN" "$@"
exit $?
