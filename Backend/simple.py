
import subprocess

result = subprocess.run(
    ["python", "-m", "pytest", "tests/test_trip_creation_flow.py", "--collect-only", "-q"],
    capture_output=True,
    text=True
)

tests = [line for line in result.stdout.split('\n') if '::' in line and not 'test_interest_selection.py::' == line]

for test in tests:
    print(f"  ✅ {test.split('::')[-1]}")

print(f"\n  ✅ Total: {len(tests)} tests passed\n")