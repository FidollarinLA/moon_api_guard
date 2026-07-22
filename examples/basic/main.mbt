///|
/// Minimal runnable example: compare two in-memory `.mbti` snapshots
/// with the public library API and print a SemVer suggestion.
fn main {
  let old_mbti =
    #|pub fn parse(String) -> Int
    #|pub fn greet(String) -> String
  let new_mbti =
    #|pub fn parse(String) -> String
    #|pub fn greet(String) -> String
    #|pub fn format(Int) -> String
  let report = @lib.compare_mbti_content(old_mbti, new_mbti)
  println("example: moon_api_guard basic compare")
  println("breaking: \{report.breaking_count()}")
  println("compatible: \{report.compatible_count()}")
  println("semver: \{report.semver_suggestion()}")
  println("release_blocked: \{report.release_blocked()}")
  println(report.markdown_summary())
}
