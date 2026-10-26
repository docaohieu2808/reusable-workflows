package fixture;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import org.junit.jupiter.api.Test;

class CalcTest {
    @Test
    void adds() {
        assertEquals(5, Calc.add(2, 3));
    }

    // The self-test sets FIXTURE_FAIL=1 to prove that a failing test turns the pipeline red.
    @Test
    void failsOnRequest() {
        assertNotEquals("1", System.getenv("FIXTURE_FAIL"));
    }
}
