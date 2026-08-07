#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
FORMULAS="$ROOT/apothecary/formulas"
failures=0
network_formulas=0
verified_formulas=0

while IFS= read -r formula; do
    # Ignore comments when deciding whether a formula performs network I/O.
    active=$(sed -E '/^[[:space:]]*#/d' "$formula")
    if ! printf '%s\n' "$active" | grep -Eq '(^|[[:space:]])(downloader|curl|git clone)([[:space:]]|$)'; then
        continue
    fi
    network_formulas=$((network_formulas + 1))

    if printf '%s\n' "$active" | grep -Eq 'verify_sha256|verify_git_commit|commit mismatch'; then
        verified_formulas=$((verified_formulas + 1))
    else
        printf 'Missing source verification: %s\n' "${formula#$ROOT/}" >&2
        failures=$((failures + 1))
    fi

    if printf '%s\n' "$active" | grep -Eq "SHA(256)?=[[:space:]]*(\"\"|'')"; then
        printf 'Empty checksum declaration: %s\n' "${formula#$ROOT/}" >&2
        failures=$((failures + 1))
    fi
done < <(find "$FORMULAS" -type f -name '*.sh' | sort)

printf 'Formula source verification: %d/%d networked scripts covered\n' \
    "$verified_formulas" "$network_formulas"
[[ "$failures" -eq 0 ]]
