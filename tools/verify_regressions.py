"""Run bounded Godot checks and require explicit completion markers, not exit code alone."""
import argparse, datetime, hashlib, json, re, subprocess, time, uuid
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--godot", default="D:/Godot/Godot_v4.7.2-stable_win64.exe")
parser.add_argument("--native", action="store_true")
parser.add_argument("--only", nargs="*")
args = parser.parse_args()
project = Path(__file__).resolve().parent.parent
selected = sorted((project / "tests").glob("test_*.gd"))
if args.only:
    unknown = set(args.only) - {p.stem for p in selected}
    if unknown:
        parser.error("Unknown test names: " + ", ".join(sorted(unknown)))
    selected = [p for p in selected if p.stem in args.only]
run = project.parent / "verification" / ("regressions-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6])
run.mkdir(parents=True)
head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=project, capture_output=True, text=True, check=True).stdout.strip()
results = []
for test in selected:
    command = [args.godot] + ([] if args.native else ["--headless"]) + ["--path", str(project), "--fixed-fps", "60", "--script", "res://tests/" + test.name, "--quit-after", "18000"]
    started = time.monotonic()
    timed_out = False
    try:
        proc = subprocess.run(command, cwd=project, capture_output=True, timeout=45)
        output = (proc.stdout + proc.stderr).decode("utf-8", errors="replace")
        code = proc.returncode
    except subprocess.TimeoutExpired as error:
        timed_out = True
        output = ((error.stdout or b"") + (error.stderr or b"")).decode("utf-8", errors="replace")
        code = None
    (run / (test.stem + ".log")).write_text(output, encoding="utf-8")
    markers = re.findall(r"([A-Z_]+CHECKS):\s*(\d+)\s+FAILURES:\s*(\d+)", output)
    passed = code == 0 and bool(markers) and all(int(m[2]) == 0 for m in markers) and not re.search(r"SCRIPT ERROR:|ERROR:|FAIL:", output)
    result = {"test": test.stem, "test_sha256": hashlib.sha256(test.read_bytes()).hexdigest(), "passed": passed, "exit_code": code, "timeout": timed_out, "seconds": round(time.monotonic()-started, 2), "markers": markers}
    results.append(result)
    print(test.stem + ": " + ("PASS" if passed else "FAIL") + " " + str(markers), flush=True)
    report = {"passed": all(r["passed"] for r in results) and len(results)==len(selected), "source_head": head, "renderer": "native" if args.native else "headless", "scope": "bounded individual checks; headless mode does not prove GPU visual behavior, human difficulty, or full game acceptance", "expected_tests": len(selected), "completed_tests": len(results), "results": results}
    (run / "summary.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("REGRESSION_REPORT: " + str(run / "summary.json"), flush=True)
raise SystemExit(0 if report["passed"] else 1)
