#!/usr/bin/env python3
"""WorldGuard test harness (Linux S-mode + U-mode).

Strategy:
1) Run scripts/run-qemu-worldguard.sh (boots full chain with WG DT)
2) Parse serial output for WGTEST markers emitted by init script

Exit codes:
  0: PASS marker found
  1: FAIL marker found or timeout
  3: QEMU failed to start
"""

import os
import re
import signal
import subprocess
import sys
from datetime import datetime
from pathlib import Path


TIMEOUT_SECONDS = 240


def find_project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def run_qemu(project_root: Path, timeout: int):
    run_script = project_root / "scripts" / "run-qemu-linux-worldguard-test.sh"
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
            stdin=subprocess.DEVNULL,
            env=env,
            cwd=str(project_root),
        )
    except OSError as e:
        print(f"ERROR: Failed to start QEMU: {e}", file=sys.stderr)
        return None, 3

    output_lines: list[str] = []
    saw_pass = False
    saw_fail = False

    def timeout_handler(signum, frame):
        raise TimeoutError("WorldGuard test timeout exceeded")

    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(timeout)

    try:
        while True:
            assert process.stdout is not None
            line = process.stdout.readline()
            if not line:
                if process.poll() is not None:
                    break
                continue

            decoded = line.decode("utf-8", errors="replace")
            output_lines.append(decoded)

            if re.search(r"WGTEST: PASS", decoded):
                saw_pass = True
                break
            if re.search(r"WGTEST: FAIL", decoded):
                saw_fail = True
                break

    except TimeoutError:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        return "".join(output_lines), 1
    finally:
        signal.alarm(0)
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()

    output = "".join(output_lines)
    if saw_pass and not saw_fail:
        return output, 0
    return output, 1


def save_logs(project_root: Path, output: str, exit_code: int):
    log_dir = project_root / "build" / "test-logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_file = log_dir / f"worldguard-test-{timestamp}.log"
    result_file = log_dir / f"worldguard-test-{timestamp}.result"

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
    print("=== WorldGuard Test (Linux S/U) ===")
    print(f"Project: {project_root}")
    print(f"Timeout: {TIMEOUT_SECONDS}s")
    print()

    output, exit_code = run_qemu(project_root, TIMEOUT_SECONDS)
    save_logs(project_root, output or "", exit_code)

    if exit_code == 0:
        print("[RESULT] PASS - WGTEST: PASS found")
    else:
        print("[RESULT] FAIL - WGTEST: FAIL or timeout")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
