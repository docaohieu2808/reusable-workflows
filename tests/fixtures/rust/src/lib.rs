//! The smallest Rust crate the pipeline can build and test.

/// Returns `a + b`.
pub fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::add;

    #[test]
    fn adds() {
        assert_eq!(add(2, 3), 5);
    }

    // The self-test sets FIXTURE_FAIL=1 to prove that a failing test turns the pipeline red.
    #[test]
    fn fails_on_request() {
        assert_ne!(std::env::var("FIXTURE_FAIL").as_deref(), Ok("1"));
    }
}
