#!/usr/bin/env bash
# Fails if line coverage (generated *.g.dart / *.freezed.dart excluded) is
# below the threshold. Usage: tool/check_coverage.sh [min-percent]
set -euo pipefail
min="${1:-80}"
awk -v min="$min" '
  /^SF:/ { skip = ($0 ~ /\.(g|freezed)\.dart$/) }
  /^LF:/ && !skip { total += substr($0, 4) }
  /^LH:/ && !skip { hit += substr($0, 4) }
  END {
    pct = total ? hit * 100 / total : 0
    printf "Line coverage: %.1f%% (%d/%d), minimum %d%%\n", pct, hit, total, min
    exit (pct < min)
  }
' coverage/lcov.info
