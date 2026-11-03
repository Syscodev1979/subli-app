#!/usr/bin/env bash
# Egy parancs: emulátor, üres adatbázisnál mintaadat, majd a fejlesztői app
# a már futó szimulátoron. Felhőbe nem telepít.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${JAVA_HOME:-}" ] && [ -x /opt/homebrew/opt/openjdk/bin/java ]; then
  export JAVA_HOME=/opt/homebrew/opt/openjdk
  export PATH="$JAVA_HOME/bin:$PATH"
fi

port_up() {
  code=$(curl -s -o /dev/null --max-time 2 -w "%{http_code}" "http://127.0.0.1:$1/" || true)
  [ -n "$code" ] && [ "$code" != "000" ]
}

mkdir -p .emulator-data
if ! port_up 4000; then
  echo "Emulátor indul…"
  tool/emulator_start.sh >.emulator-data/emulator.log 2>&1 &
  ready=0
  for _ in $(seq 1 90); do
    if port_up 4000; then
      ready=1
      break
    fi
    sleep 1
  done
  if [ "$ready" -ne 1 ]; then
    echo "Az emulátor nem indult el. A napló: .emulator-data/emulator.log" >&2
    exit 1
  fi
fi

users=$(curl -sf -H "Authorization: Bearer owner" \
  "http://127.0.0.1:8080/v1/projects/demo-subli/databases/(default)/documents/users?pageSize=1" \
  || true)
if ! printf '%s' "$users" | grep -q '"documents"'; then
  echo "Mintaadat betöltése…"
  node tool/seed_emulator.mjs
fi

device=$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-Fa-f-]\{36\}\)) (Booted).*/\1/p' | head -1)
if [ -z "$device" ]; then
  echo "Nincs futó szimulátor. Indítsd el, aztán futtasd újra." >&2
  exit 1
fi

exec flutter run --flavor dev -t lib/main.dart -d "$device"
