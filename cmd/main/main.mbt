///|
/// Minimal public API compatibility report example.
fn main {
  let old_api = [@lib.api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = [@lib.api_item("fn", "parse", "pub fn parse(String) -> String")]
  let report = @lib.compare_api(old_api, new_api)
  println("moon_api_guard report")
  println("breaking: \{report.breaking_count()}")
  println("semver: \{report.semver_suggestion()}")
}
