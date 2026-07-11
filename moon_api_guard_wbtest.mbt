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
test "suggests patch when public api is unchanged" {
  let old_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="0")
  inspect(report.compatible_count(), content="0")
  inspect(report.semver_suggestion(), content="patch")
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

///|
test "parses public type and alias declarations" {
  let items = parse_mbti_items([
    "pub(all) type UserId", "pub(all) typealias Name = String",
  ])
  inspect(items.length(), content="2")
  inspect(items[0].kind, content="type")
  inspect(items[1].kind, content="alias")
}

///|
test "renders markdown report summary" {
  let report = compare_api(
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
    [api_item("fn", "parse", "pub fn parse(String) -> String")],
  )
  inspect(
    report.markdown_summary(),
    content="# moon_api_guard report\n\n- breaking: 1\n- compatible: 0\n- semver: major",
  )
}

///|
test "blocks release when breaking changes exist" {
  let breaking_report = compare_api(
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
    [],
  )
  let compatible_report = compare_api(
    [],
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
  )
  inspect(breaking_report.release_blocked(), content="true")
  inspect(compatible_report.release_blocked(), content="false")
}

///|
test "renders json report summary" {
  let report = compare_api(
    [],
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
  )
  inspect(
    report.json_summary(),
    content="{\"breaking\":0,\"compatible\":1,\"semver\":\"minor\",\"release_blocked\":false}",
  )
}
