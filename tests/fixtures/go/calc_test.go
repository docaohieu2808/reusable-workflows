package fixture

import (
	"os"
	"testing"
)

func TestAdd(t *testing.T) {
	if got := Add(2, 3); got != 5 {
		t.Fatalf("Add(2, 3) = %d, want 5", got)
	}
}

// The self-test sets FIXTURE_FAIL=1 to prove that a failing test turns the pipeline red.
func TestFailsOnRequest(t *testing.T) {
	if os.Getenv("FIXTURE_FAIL") == "1" {
		t.Fatal("FIXTURE_FAIL=1")
	}
}
