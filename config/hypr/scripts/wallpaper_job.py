#!/usr/bin/env python3
"""Apply a wallpaper and replace any unfinished palette job with the latest one."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def process_identity(pid):
    """Include start time so an old PID file cannot target a reused process ID."""
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        return fields[19], fields[0]
    except (OSError, IndexError):
        return None, None


def stop_previous(job):
    pid = job.get("pid")
    if not isinstance(pid, int) or pid <= 1:
        return
    started, state = process_identity(pid)
    if started != job.get("started") or state in (None, "Z"):
        return
    try:
        if os.getpgid(pid) != pid:
            return
        os.killpg(pid, signal.SIGTERM)
        until = time.monotonic() + .25
        while time.monotonic() < until:
            try:
                os.killpg(pid, 0)
            except ProcessLookupError:
                return
            time.sleep(.01)
        os.killpg(pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("wallpaper", type=Path)
    args = parser.parse_args()
    wallpaper = args.wallpaper.expanduser().resolve(strict=True)
    scripts = Path.home() / ".config/hypr/scripts"
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", str(Path.home() / ".cache")))
    directory = runtime / "portfolio-wallpaper"
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    state_path = directory / "job.json"
    # Serialize only cancelling/starting jobs, never the lengthy color extraction.
    with (directory / "control.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if state_path.exists():
            stop_previous(json.loads(state_path.read_text()))
        subprocess.run([str(scripts / "start_wallpaper.sh")], check=True, timeout=8)
        subprocess.run(["awww", "img", str(wallpaper), "--transition-fps", "30",
                        "--transition-type", "wipe", "--transition-duration", "1"],
                       check=True, timeout=8)
        # The daemon starts outside this process group, so cancelling colors
        # cannot accidentally stop the wallpaper daemon too.
        log = Path.home() / ".cache/theme/wallpaper-worker.log"
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("w") as output:
            worker = subprocess.Popen(
                [str(scripts / "pywal_awww.sh"), str(wallpaper)],
                stdin=subprocess.DEVNULL, stdout=output, stderr=output,
                start_new_session=True, close_fds=True,
            )
        started, _ = process_identity(worker.pid)
        state = {"pid": worker.pid, "started": started, "wallpaper": str(wallpaper)}
        temporary = state_path.with_suffix(".tmp")
        temporary.write_text(json.dumps(state) + "\n")
        temporary.replace(state_path)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"wallpaper_job: {error}", file=sys.stderr)
        sys.exit(1)
