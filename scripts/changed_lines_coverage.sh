#!/usr/bin/env bash
# Reports test coverage of the lines ADDED/CHANGED vs a base ref, not whole files.
#
# Usage (run from the repo root; needs git):
#   scripts/changed_lines_coverage.sh [base-ref]      # default base: HEAD (uncommitted work)
#   e.g. scripts/changed_lines_coverage.sh main       # whole branch vs its merge-base with main
#
# Runs `flutter test --coverage --branch-coverage`, then intersects `git diff -U0`
# with coverage/lcov.info. Exit 1 if the policy in .claude/rules/tests.md is broken:
#   - all changed lines together < 90% covered (hard floor; target is 100%, every gap justified in the report), or
#   - an added line contains a `coverage:ignore` comment (it hides lines from lcov; report it as a gap).
# Changed files with no lcov data are listed: either no test loads them or they have no executable lines.
# Set SKIP_TESTS=1 to reuse an existing coverage/lcov.info.
set -euo pipefail

BASE="${1:-HEAD}"
LCOV="coverage/lcov.info"
FLOOR=90
# Excluded from the report: generated, barrel, entry/wiring files (see tests.md).
EXCLUDE='(\.g\.dart|\.mocks\.dart|^lib/l10n/gen/.*|^lib/main\.dart|^lib/app/routes\.dart|^lib/core/di/.*)$'

[[ "${SKIP_TESTS:-0}" == 1 ]] || flutter test --coverage --branch-coverage
[[ -f "$LCOV" ]] || { echo "missing $LCOV" >&2; exit 2; }

# Diff from the merge-base so commits that only landed on BASE don't count as changes.
FROM="$(git merge-base "$BASE" HEAD)"
DIFF="$(mktemp)"
trap 'rm -f "$DIFF"' EXIT

# Diff vs base covers tracked changes (R: renamed-and-edited files); untracked files count as fully added.
git diff -U0 --no-ext-diff --src-prefix=a/ --dst-prefix=b/ --diff-filter=AMR "$FROM" -- 'lib/*.dart' > "$DIFF"
for f in $(git ls-files --others --exclude-standard -- 'lib/*.dart'); do
  git diff -U0 --no-ext-diff --src-prefix=a/ --dst-prefix=b/ --no-index /dev/null "$f" >> "$DIFF" || true
done

awk -v exclude="$EXCLUDE" -v floor="$FLOOR" '
  FNR == NR {                       # pass 1: diff -> changed[file,line]
    if ($0 ~ /^\+\+\+ /) { f = substr($0, 7); if ($0 ~ /\/dev\/null/) f = ""; else if (f !~ exclude) touched[f] = 1; next }
    if ($0 ~ /^@@/ && f != "") {
      split($0, p, "+"); split(p[2], q, " "); split(q[1], r, ",")
      s = r[1]; c = (r[2] == "" ? 1 : r[2]); ln = s
      for (i = 0; i < c; i++) changed[f, s + i] = 1
      next
    }
    if ($0 ~ /^\+/ && f != "" && f !~ exclude) {
      if ($0 ~ /coverage:ignore/) ignores = ignores "\n  " f ":" ln
      ln++
    }
    next
  }
  /^SF:/ { sf = substr($0, 4); hasdata[sf] = 1; next }      # pass 2: lcov
  /^DA:/ { split(substr($0, 4), d, ","); line[sf, d[1]] = d[2]; files[sf] = 1; next }
  END {
    bad = 0; alltot = allcov = 0
    for (f in files) {
      if (f ~ exclude) continue
      tot = cov = 0; gaps = ""
      for (k in line) {
        split(k, kk, SUBSEP); if (kk[1] != f) continue
        if ((f, kk[2]) in changed) { tot++; if (line[k] > 0) cov++; else gaps = gaps " " kk[2] }
      }
      if (tot == 0) continue
      alltot += tot; allcov += cov
      printf "%-70s changed %d/%d (%.0f%%)%s\n", f, cov, tot, 100 * cov / tot, (gaps != "" ? "  UNCOVERED:" gaps : "")
    }
    if (alltot > 0) {
      printf "\nTOTAL changed lines %d/%d (%.1f%%), floor %d%%\n", allcov, alltot, 100 * allcov / alltot, floor
      if (100 * allcov / alltot < floor) bad = 1
    }
    nodata = ""
    for (f in touched) if (!(f in hasdata)) nodata = nodata "\n  " f
    if (nodata != "") print "\nNO COVERAGE DATA (no test loads it, or it has no executable lines; confirm which):" nodata
    if (ignores != "") { print "\nADDED coverage:ignore COMMENTS (each is a gap):" ignores; bad = 1 }
    if (bad) print "\nFAIL: add tests, or justify every gap in the report (.claude/rules/tests.md)"
    else if (allcov < alltot) print "\nOK (above floor): list every UNCOVERED line under Gaps: with a reason"
    else print "\nOK: all changed lines covered"
    exit bad
  }
' "$DIFF" "$LCOV"
