#!/usr/bin/env bash
# A helyi Firebase-emulátor. Felhőbe nem telepít.
# Az adat a .emulator-data mappába kerül, és onnan töltődik vissza.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${JAVA_HOME:-}" ] && [ -x /opt/homebrew/opt/openjdk/bin/java ]; then
  export JAVA_HOME=/opt/homebrew/opt/openjdk
  export PATH="$JAVA_HOME/bin:$PATH"
fi

mkdir -p .emulator-data
if [ -f .emulator-data/firebase-export-metadata.json ]; then
  exec firebase emulators:start \
    --project demo-subli \
    --only auth,firestore,storage,functions \
    --import=.emulator-data \
    --export-on-exit=.emulator-data
fi

exec firebase emulators:start \
  --project demo-subli \
  --only auth,firestore,storage,functions \
  --export-on-exit=.emulator-data
