#!/usr/bin/env bash
# Fails if Roboto test fonts exist outside flutter_adaptive_cards_test_support.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
canonical="$repo_root/packages/flutter_adaptive_cards_test_support/assets/fonts/Roboto"

duplicates=()
while IFS= read -r -d '' path; do
  if [[ "$path" != "$canonical/"* ]]; then
    duplicates+=("$path")
  fi
done < <(find "$repo_root/packages" -path '*/assets/fonts/Roboto/*.ttf' -print0 2>/dev/null)

if ((${#duplicates[@]} > 0)); then
  echo "Duplicate Roboto font assets found outside test_support:" >&2
  printf '  %s\n' "${duplicates[@]}" >&2
  exit 1
fi

echo "No duplicate Roboto font assets outside test_support."
