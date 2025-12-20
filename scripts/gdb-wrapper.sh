#!/bin/bash
# Wrapper to wait for port 1234 before launching GDB
# Needed because VS Code might launch debugger before QEMU binds the port.

HOST="localhost"
PORT="1234"
TIMEOUT=10

# Wait for port to open
start_ts=$(date +%s)
while ! nc -z $HOST $PORT > /dev/null 2>&1; do
    curr_ts=$(date +%s)
    if [ $((curr_ts - start_ts)) -gt $TIMEOUT ]; then
        echo "Error: Timed out waiting for QEMU on $HOST:$PORT" >&2
        exit 1
    fi
    sleep 0.2
done

# Launch GDB
exec /usr/bin/gdb-multiarch "$@"
