"""Generic BDD proof runner for the dart-flutter stack.

Each behave scenario carries exactly one @proof_<id> tag and is bound to a
Flutter test tagged @Tags(['proof_<id>']). The step just executes that bound
proof via `flutter test --tags proof_<id>` and inherits its verdict — behave
never inspects Dart source (that would be structure, not behavior).
"""

import shutil
import subprocess
from pathlib import Path

from behave import given, when, then

# proof_steps.py lives at <repo>/features/steps/proof_steps.py, so parents[2]
# is the repo root — the cwd for `flutter test` in this single-app repo.
REPO = Path(__file__).resolve().parents[2]

# `flutter` is `flutter.bat` on Windows; a bare arg list won't resolve it, so
# resolve the real executable path up front.
FLUTTER = shutil.which("flutter") or "flutter"


def _proof_tag(context):
    tags = [t for t in context.scenario.tags if t.startswith("proof_")]
    assert len(tags) == 1, f"need exactly one @proof_<id> tag, found {tags or 'none'}"
    return tags[0]


@given("a bound integration proof")
def step_bound(context):
    context.proof_tag = _proof_tag(context)


@when("the bound integration proof is executed")
def step_execute(context):
    context.result = subprocess.run(
        [FLUTTER, "test", "--tags", context.proof_tag],
        cwd=str(REPO),
        capture_output=True,
        text=True,
    )


@then("it passes")
def step_passes(context):
    assert context.result.returncode == 0, (
        f"bound proof '{context.proof_tag}' failed "
        f"(exit {context.result.returncode})\n{context.result.stdout}"
    )
