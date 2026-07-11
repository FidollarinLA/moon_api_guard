///|
/// Minimal public API compatibility report example.
fn main {
  let old_api = [@lib.api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = [
    @lib.api_item("fn", "parse", "pub fn parse(String) -> String"),
    @lib.api_item("fn", "format", "pub fn format(Int) -> String"),
  ]
  let report = @lib.compare_api(old_api, new_api)
  println("moon_api_guard report")
  println("breaking: \{report.breaking_count()}")
  println("compatible: \{report.compatible_count()}")
  println("semver: \{report.semver_suggestion()}")
  println("release_blocked: \{report.release_blocked()}")
  println(report.markdown_summary())
  println(report.json_summary())
}
