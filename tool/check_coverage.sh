#!/usr/bin/env bash
# Fails if line coverage is below the threshold. Excluded: build_runner,
# drift make-migrations and gen-l10n output, and drift table definitions
# (a DSL read by the code generator, never executed). Usage: tool/check_coverage.sh [min-percent]
set -euo pipefail
min="${1:-80}"
awk -v min="$min" '
  /^SF:/ {
    skip = ($0 ~ /\.(g|freezed|steps)\.dart$/ ||
            $0 ~ /lib\/l10n\/app_localizations/ ||
            $0 ~ /lib\/data\/database\/tables\.dart$/)
  }
  /^LF:/ && !skip { total += substr($0, 4) }
  /^LH:/ && !skip { hit += substr($0, 4) }
  END {
    pct = total ? hit * 100 / total : 0
    printf "Line coverage: %.1f%% (%d/%d), minimum %d%%\n", pct, hit, total, min
    exit (pct < min)
  }
' coverage/lcov.info
