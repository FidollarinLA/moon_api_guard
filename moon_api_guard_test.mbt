///|
test "public api compare workflow" {
  let old_items = @moon_api_guard.parse_mbti_content(
    "pub fn parse(String) -> Int",
  )
  let new_items = @moon_api_guard.parse_mbti_content(
    "pub fn parse(String) -> String",
  )
  let report = @moon_api_guard.compare_api(old_items, new_items)
  inspect(report.breaking_count(), content="1")
  inspect(report.compatible_count(), content="0")
  inspect(report.semver_suggestion(), content="major")
  inspect(report.release_blocked(), content="true")
}

///|
test "public api item constructor" {
  let item = @moon_api_guard.api_item(
    "fn", "parse", "pub fn parse(String) -> Int",
  )
  inspect(item.kind, content="fn")
  inspect(item.name, content="parse")
}

///|
test "public markdown report lists change details" {
  let report = @moon_api_guard.compare_api(
    @moon_api_guard.parse_mbti_items(["pub fn parse(String) -> Int"]),
    @moon_api_guard.parse_mbti_items(["pub fn parse(String) -> String"]),
  )
  inspect(
    report.markdown_summary(),
    content="# moon_api_guard report\n\n- breaking: 1\n- compatible: 0\n- semver: major\n\n## Changes\n\n- kind: fn, name: parse, message: return type changed from Int to String",
  )
}

///|
test "public json report includes changes array" {
  let report = @moon_api_guard.compare_api(
    [],
    @moon_api_guard.parse_mbti_items(["pub fn parse(String) -> Int"]),
  )
  inspect(
    report.json_summary(),
    content="{\"breaking\":0,\"compatible\":1,\"semver\":\"minor\",\"release_blocked\":false,\"changes\":[{\"category\":\"compatible\",\"detail\":\"added\",\"kind\":\"fn\",\"name\":\"parse\",\"message\":\"fn parse was added\"}]}",
  )
}

///|
test "public change json object escapes quotes" {
  let report = @moon_api_guard.compare_api(
    [@moon_api_guard.api_item("fn", "say", "pub fn say(String) -> String")],
    [],
  )
  inspect(
    report.changes[0].json_object(),
    content="{\"category\":\"breaking\",\"detail\":\"removed\",\"kind\":\"fn\",\"name\":\"say\",\"message\":\"fn say was removed\"}",
  )
}

///|
test "public parse mbti content handles multiline declarations" {
  let content = "pub(all) enum Status {\n  Ok\n  Error(String)\n}\npub trait Formatter {\n  fn format(Self) -> String\n}\n"
  let items = @moon_api_guard.parse_mbti_content(content)
  inspect(items.length(), content="2")
  inspect(items[0].kind, content="enum")
  inspect(items[1].kind, content="trait")
}
