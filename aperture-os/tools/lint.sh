#!/usr/bin/env bash
# Aperture OS – Syntax check of all committed files (locally and in GitLab CI).
#   tools/lint.sh
# Parse JSON / XML / SVG, compile Python, bash -n + shellcheck (warnings), qmlformat as QML syntax check.
# If shellcheck or qmlformat is missing, the step is skipped with a notice.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
fail=0
files() { git ls-files -z -- "$@"; }
section() { printf '\n== %s\n' "$*"; }

section "JSON"
files '*.json' | xargs -0 python3 -c '
import json, sys
bad = 0
for f in sys.argv[1:]:
    try: json.load(open(f, encoding="utf-8"))
    except Exception as e: print(f"{f}: {e}"); bad = 1
print(f"{len(sys.argv) - 1} files"); sys.exit(bad)' || fail=1

section "XML / SVG"
files '*.xml' '*.svg' '*.kcfg' | xargs -0 python3 -c '
import sys, xml.etree.ElementTree as ET
bad = 0
for f in sys.argv[1:]:
    try: ET.parse(f)
    except Exception as e: print(f"{f}: {e}"); bad = 1
print(f"{len(sys.argv) - 1} files"); sys.exit(bad)' || fail=1

section "Python"
files '*.py' | xargs -0 python3 -c '
import sys
bad = 0
for f in sys.argv[1:]:
    try: compile(open(f, encoding="utf-8").read(), f, "exec")
    except SyntaxError as e: print(f"{f}: {e}"); bad = 1
print(f"{len(sys.argv) - 1} files"); sys.exit(bad)' || fail=1

section "Shell"
mapfile -d '' SH < <(files '*.sh')
for f in "${SH[@]}"; do bash -n "$f" || fail=1; done
echo "bash -n: ${#SH[@]} files"
if command -v shellcheck >/dev/null; then
    shellcheck -S warning "${SH[@]}" && echo "shellcheck: ok" || fail=1
else
    echo "shellcheck missing – skipped"
fi

section "QML"
QMLFORMAT="$(command -v qmlformat || true)"
[[ -z "$QMLFORMAT" && -x /usr/lib/qt6/bin/qmlformat ]] && QMLFORMAT=/usr/lib/qt6/bin/qmlformat
if [[ -n "$QMLFORMAT" ]]; then
    mapfile -d '' QML < <(files '*.qml')
    for f in "${QML[@]}"; do
        "$QMLFORMAT" "$f" >/dev/null 2>"${TMPDIR:-/tmp}/qmlformat.err" || { echo "$f:"; cat "${TMPDIR:-/tmp}/qmlformat.err"; fail=1; }
    done
    echo "qmlformat: ${#QML[@]} files"
else
    echo "qmlformat missing (qt6-declarative-dev-tools) – skipped"
fi

echo
if [[ $fail -ne 0 ]]; then echo "LINT FAILED"; exit 1; fi
echo "all ok"
