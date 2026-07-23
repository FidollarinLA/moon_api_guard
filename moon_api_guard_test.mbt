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

///|
test "public compare_mbti_content convenience entry" {
  let report = @moon_api_guard.compare_mbti_content(
    "pub fn parse(String) -> Int", "pub fn parse(String) -> String",
  )
  inspect(report.release_blocked(), content="true")
  inspect(report.changes[0].detail, content="return-type-changed")
}

///|
test "public breaking_only filters compatible changes" {
  let report = @moon_api_guard.compare_mbti_content(
    "pub fn parse(String) -> Int", "pub fn parse(String) -> String\npub fn format(Int) -> String",
  )
  let breaking = report.breaking_only()
  inspect(report.compatible_count(), content="1")
  inspect(breaking.compatible_count(), content="0")
  inspect(breaking.breaking_count(), content="1")
}

///|
test "public scoped and merge reports for multi-file workflows" {
  let left = @moon_api_guard.compare_mbti_content(
    "pub fn parse(String) -> Int", "pub fn parse(String) -> String",
  ).scoped("pkg.mbti")
  let right = @moon_api_guard.file_added_report("only_new.mbti")
  let merged = @moon_api_guard.merge_api_reports([left, right])
  inspect(merged.breaking_count(), content="1")
  inspect(merged.compatible_count(), content="1")
  inspect(merged.changes[0].name, content="pkg.mbti::parse")
  inspect(merged.changes[1].detail, content="file-added")
}

///|
test "public default policy treats optional params as compatible" {
  let report = @moon_api_guard.compare_mbti_content(
    "pub fn write(String) -> Unit", "pub fn write(String, encoding? : String) -> Unit",
  )
  inspect(report.release_blocked(), content="false")
  inspect(report.changes[0].detail, content="optional-parameter-added")
}

///|
test "public policy allow can relax enum variant addition" {
  let policy = @moon_api_guard.policy_allow(
    @moon_api_guard.strict_compat_policy(),
    "variant-added",
  )
  let report = @moon_api_guard.compare_mbti_content_with_policy(
    "pub(all) enum Status {\n  Ok\n}", "pub(all) enum Status {\n  Ok\n  Warning\n}",
    policy,
  )
  inspect(report.breaking_count(), content="0")
  inspect(report.compatible_count(), content="1")
}

///|
test "public policy_from_json_text loads strict allow ignore" {
  let policy = @moon_api_guard.policy_from_json_text(
    "{\"strict\":true,\"allow\":[\"variant-added\"],\"ignore\":[\"deprecated\"]}",
  )
  inspect(policy is Some(_), content="true")
  match policy {
    Some(loaded) => {
      inspect(loaded.overrides.length(), content="2")
      let report = @moon_api_guard.compare_mbti_content_with_policy(
        "pub(all) enum Status {\n  Ok\n}", "pub(all) enum Status {\n  Ok\n  Warning\n}",
        loaded,
      )
      inspect(report.breaking_count(), content="0")
    }
    None => inspect(false, content="true")
  }
}

///|
test "public policy_from_json_text rejects invalid json" {
  inspect(@moon_api_guard.policy_from_json_text("{") is None, content="true")
  inspect(
    @moon_api_guard.policy_from_json_text("{\"strict\":\"yes\"}") is None,
    content="true",
  )
}

///|
test "public regression-style base64 optional params stay compatible" {
  let old = "package \"example/base64\"\npub fn encode(BytesView) -> String\npub fn Decoder::decode_to(Self, StringView, (Byte) -> Unit) -> Unit raise DecodeError\n"
  let new = "package \"example/base64\"\npub fn encode(BytesView, url_safe? : Bool) -> String\npub fn Decoder::decode_to(Self, StringView, (Byte) -> Unit, url_safe? : Bool) -> Unit raise DecodeError\n"
  let report = @moon_api_guard.compare_mbti_content(old, new)
  inspect(report.release_blocked(), content="false")
  inspect(report.compatible_count(), content="2")
  inspect(report.changes[1].detail, content="optional-parameter-added")
}
