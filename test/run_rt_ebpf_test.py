#!/usr/bin/env python3
"""PREEMPT_RT + eBPF runtime test harness.

Strategy:
1) Boot guest with `scripts/run_qemu.sh`
2) Login to Buildroot shell
3) Execute PREEMPT_RT/eBPF validation commands in guest

Exit codes:
  0: All checks passed
  1: Validation failed or timeout
  3: QEMU failed to start
"""

import os
import re
import select
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


TIMEOUT_SECONDS = 240
LOGIN_PATTERN = re.compile(r"buildroot login:")
SHELL_PATTERN = re.compile(r"\n# ")


def find_project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _read_until(
    process: subprocess.Popen,
    output_chunks: list[str],
    window: str,
    pattern: re.Pattern[str],
    deadline: float,
):
    while True:
        if time.monotonic() >= deadline:
            return False, window

        timeout_s = max(0.0, min(1.0, deadline - time.monotonic()))
        assert process.stdout is not None
        ready, _, _ = select.select([process.stdout], [], [], timeout_s)
        if not ready:
            if process.poll() is not None:
                return False, window
            continue

        chunk = os.read(process.stdout.fileno(), 4096)
        if not chunk:
            if process.poll() is not None:
                return False, window
            continue

        decoded = chunk.decode("utf-8", errors="replace")
        output_chunks.append(decoded)
        window += decoded
        window = window[-65536:]

        if pattern.search(window):
            return True, window


def _run_guest_command(
    process: subprocess.Popen,
    output_chunks: list[str],
    window: str,
    command: str,
    marker_idx: int,
    deadline: float,
):
    marker = f"__RTEBPF_RC_{marker_idx}__"
    marker_pattern = re.compile(rf"{re.escape(marker)}:(\d+)")

    assert process.stdin is not None
    process.stdin.write(f"{command}; echo {marker}:$?\r".encode("utf-8"))
    process.stdin.flush()

    while True:
        if time.monotonic() >= deadline:
            return False, 1, window

        timeout_s = max(0.0, min(1.0, deadline - time.monotonic()))
        assert process.stdout is not None
        ready, _, _ = select.select([process.stdout], [], [], timeout_s)
        if not ready:
            if process.poll() is not None:
                return False, 1, window
            continue

        chunk = os.read(process.stdout.fileno(), 4096)
        if not chunk:
            if process.poll() is not None:
                return False, 1, window
            continue

        decoded = chunk.decode("utf-8", errors="replace")
        output_chunks.append(decoded)
        window += decoded
        window = window[-131072:]

        match = marker_pattern.search(window)
        if match:
            return True, int(match.group(1)), window


def run_qemu(project_root: Path, timeout: int):
    run_script = project_root / "scripts" / "run_qemu.sh"
    if not run_script.exists():
        print(f"ERROR: {run_script} not found", file=sys.stderr)
        return None, 3

    env = os.environ.copy()
    env["TERM"] = "dumb"

    try:
        process = subprocess.Popen(
            [str(run_script)],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.PIPE,
            env=env,
            cwd=str(project_root),
        )
    except OSError as e:
        print(f"ERROR: Failed to start QEMU: {e}", file=sys.stderr)
        return None, 3

    output_chunks: list[str] = []
    scan_window = ""
    deadline = time.monotonic() + timeout

    try:
        ok, scan_window = _read_until(
            process, output_chunks, scan_window, LOGIN_PATTERN, deadline
        )
        if not ok:
            return "".join(output_chunks), 1

        assert process.stdin is not None
        process.stdin.write(b"root\r")
        process.stdin.flush()

        ok, scan_window = _read_until(
            process, output_chunks, scan_window, SHELL_PATTERN, deadline
        )
        if not ok:
            return "".join(output_chunks), 1

        checks = [
            ("preempt_rt", "uname -v | grep -q PREEMPT_RT"),
            ("bpftool exists", "command -v bpftool >/dev/null 2>&1"),
            ("tc exists", "command -v tc >/dev/null 2>&1"),
            ("bpftool command", "bpftool prog help >/dev/null 2>&1"),
            ("tc command", "tc -V >/dev/null 2>&1"),
        ]

        for idx, (name, cmd) in enumerate(checks, start=1):
            output_chunks.append(f"\n[CHECK] {name}: {cmd}\n")
            ok, rc, scan_window = _run_guest_command(
                process, output_chunks, scan_window, cmd, idx, deadline
            )
            if not ok or rc != 0:
                output_chunks.append(f"[CHECK] FAIL: {name} (rc={rc})\n")
                process.stdin.write(b"poweroff -f || true\r")
                process.stdin.flush()
                return "".join(output_chunks), 1

            output_chunks.append(f"[CHECK] PASS: {name}\n")

        process.stdin.write(b"poweroff -f || true\r")
        process.stdin.flush()
        return "".join(output_chunks), 0
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()


def save_logs(project_root: Path, output: str, exit_code: int):
    log_dir = project_root / "build" / "test-logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_file = log_dir / f"rt-ebpf-test-{timestamp}.log"
    result_file = log_dir / f"rt-ebpf-test-{timestamp}.result"

    if output:
        log_file.write_text(output)
        print(f"[LOG] Saved: {log_file}")

    status = "PASS" if exit_code == 0 else "FAIL"
    result_file.write_text(
        f"Status: {status}\nExit Code: {exit_code}\nTimestamp: {timestamp}\n"
    )
    print(f"[RESULT] Saved: {result_file}")


def main() -> int:
    project_root = find_project_root()
    print("=== PREEMPT_RT + eBPF Runtime Test ===")
    print(f"Project: {project_root}")
    print(f"Timeout: {TIMEOUT_SECONDS}s")
    print()

    output, exit_code = run_qemu(project_root, TIMEOUT_SECONDS)
    save_logs(project_root, output or "", exit_code)

    if exit_code == 0:
        print("[RESULT] PASS - PREEMPT_RT + eBPF checks passed")
    else:
        print("[RESULT] FAIL - check rt-ebpf-test log for details")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
