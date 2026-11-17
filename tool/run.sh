#!/bin/bash
# Runs Latch on the iPhone 17 Pro Max simulator, stdin on a FIFO:
#   echo r > /tmp/latch/fifo   hot reload     (R restart, q quit)
# The FIFO lives outside the project: a pipe inside it hangs `flutter build`.
# Extra arguments go to `flutter run` (for example --dart-define=startRoute=signIn).
cd "$(dirname "$0")/.."
mkdir -p /tmp/latch
rm -f /tmp/latch/fifo
mkfifo /tmp/latch/fifo
sleep 100000 > /tmp/latch/fifo &
HOLD=$!
trap 'kill $HOLD 2>/dev/null' EXIT
flutter run -d "${LATCH_DEVICE:-44CDDB86-D61F-47C8-8C65-7C87828A38C5}" "$@" < /tmp/latch/fifo > /tmp/latch/run.log 2>&1
