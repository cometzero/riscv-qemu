#!/usr/bin/env python3
"""
RISC-V QEMU Boot Flow Test Harness

Exit codes:
    0: All milestones found, boot successful
    1: Missing milestones or error detected
    2: Timeout (3 minutes exceeded)
    3: QEMU failed to start
"""

import os
import re
import signal
import subprocess
import sys
from datetime import datetime
from pathlib import Path

TIMEOUT_SECONDS = 180

MILESTONES = [
    ("SPL_STARTED", r"U-Boot SPL"),
    ("OPENSBI_RUNNING", r"SBI specification v"),
    ("UBOOT_RUNNING", r"U-Boot 20"),
    ("LINUX_BOOTING", r"Linux version"),
    ("BUILDROOT_READY", r"Welcome to.*Buildroot|buildroot login:"),
]

ERROR_PATTERNS = [
    r"Kernel panic",
    r"Unable to mount root fs",
    r"not syncing",
    r"Illegal instruction",
]


def find_project_root():
    script_path = Path(__file__).resolve()
    return script_path.parent.parent


def run_qemu(project_root, timeout):
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

    output_lines = []
    milestone_found = {name: False for name, _ in MILESTONES}
    error_detected = None
    final_milestone_reached = False

    def timeout_handler(signum, frame):
        raise TimeoutError("Boot timeout exceeded")

    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(timeout)

    try:
        while True:
            line = process.stdout.readline()
            if not line:
                if process.poll() is not None:
                    break
                continue

            decoded = line.decode("utf-8", errors="replace")
            output_lines.append(decoded)

            for name, pattern in MILESTONES:
                if not milestone_found[name] and re.search(pattern, decoded):
                    milestone_found[name] = True
                    print(f"[MILESTONE] {name}: {pattern}")

            for pattern in ERROR_PATTERNS:
                if re.search(pattern, decoded):
                    error_detected = pattern
                    break

            if milestone_found["BUILDROOT_READY"]:
                final_milestone_reached = True
                break

            if error_detected:
                break

    except TimeoutError:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        return "".join(output_lines), 2

    finally:
        signal.alarm(0)
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()

    output = "".join(output_lines)

    if error_detected:
        print(f"[ERROR] Detected: {error_detected}", file=sys.stderr)
        return output, 1

    if not final_milestone_reached:
        missing = [name for name, found in milestone_found.items() if not found]
        print(f"[ERROR] Missing milestones: {missing}", file=sys.stderr)
        return output, 1

    return output, 0


def save_logs(project_root, output, exit_code, milestone_status):
    log_dir = project_root / "build" / "test-logs"
    log_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_file = log_dir / f"boot-test-{timestamp}.log"
    result_file = log_dir / f"boot-test-{timestamp}.result"

    if output:
        log_file.write_text(output)
        print(f"[LOG] Saved: {log_file}")

    status = "PASS" if exit_code == 0 else "FAIL"
    result_lines = [
        f"Status: {status}",
        f"Exit Code: {exit_code}",
        f"Timestamp: {timestamp}",
        "",
        "Milestones:",
    ]
    for name, found in milestone_status.items():
        mark = "[x]" if found else "[ ]"
        result_lines.append(f"  {mark} {name}")

    result_file.write_text("\n".join(result_lines) + "\n")
    print(f"[RESULT] Saved: {result_file}")


def main():
    project_root = find_project_root()
    print(f"=== RISC-V QEMU Boot Test ===")
    print(f"Project: {project_root}")
    print(f"Timeout: {TIMEOUT_SECONDS}s")
    print()

    output, exit_code = run_qemu(project_root, TIMEOUT_SECONDS)

    milestone_status = {}
    if output:
        for name, pattern in MILESTONES:
            milestone_status[name] = bool(re.search(pattern, output))
    else:
        milestone_status = {name: False for name, _ in MILESTONES}

    save_logs(project_root, output, exit_code, milestone_status)

    print()
    if exit_code == 0:
        print("[RESULT] PASS - All milestones reached")
    elif exit_code == 2:
        print(f"[RESULT] FAIL - Timeout ({TIMEOUT_SECONDS}s)")
    elif exit_code == 3:
        print("[RESULT] FAIL - QEMU failed to start")
    else:
        print("[RESULT] FAIL - Boot incomplete or error detected")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
