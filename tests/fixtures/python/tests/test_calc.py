import os

from calc import add


def test_add():
    assert add(2, 3) == 5


def test_fails_on_request():
    # The self-test sets FIXTURE_FAIL=1 to prove that a failing test turns the pipeline red.
    assert os.environ.get("FIXTURE_FAIL") != "1"
