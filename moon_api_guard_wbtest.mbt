///|
test "detects breaking function signature changes" {
  let old_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = [api_item("fn", "parse", "pub fn parse(String) -> String")]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.semver_suggestion(), content="major")
}

///|
test "detects removed public api as breaking" {
  let old_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = []
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].message, content="fn parse was removed")
}

///|
test "classifies added public api as compatible" {
  let old_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = [
    api_item("fn", "parse", "pub fn parse(String) -> Int"),
    api_item("fn", "format", "pub fn format(Int) -> String"),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="0")
  inspect(report.compatible_count(), content="1")
  inspect(report.semver_suggestion(), content="minor")
}

///|
test "parses simple mbti public items" {
  let items = parse_mbti_items([
    "package \"skyjk/example\"", "pub fn parse(String) -> Int", "pub(all) struct Report {",
    "  issues : Array[String]", "}",
  ])
  inspect(items.length(), content="2")
  inspect(items[0].name, content="parse")
  inspect(items[1].kind, content="struct")
}
