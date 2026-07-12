///|
test "detects breaking function signature changes" {
  let old_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = [api_item("fn", "parse", "pub fn parse(String) -> String")]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="return-type-changed")
  inspect(report.semver_suggestion(), content="major")
}

///|
test "detects removed public api as breaking" {
  let old_api = [api_item("fn", "parse", "pub fn parse(String) -> Int")]
  let new_api = []
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="removed")
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
  inspect(report.changes[0].detail, content="added")
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
test "detects parameter removal" {
  let old_api = [api_item("fn", "greet", "pub fn greet(String, Int) -> String")]
  let new_api = [api_item("fn", "greet", "pub fn greet(String) -> String")]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="parameter-removed")
}

///|
test "detects parameter addition" {
  let old_api = [api_item("fn", "greet", "pub fn greet(String) -> String")]
  let new_api = [api_item("fn", "greet", "pub fn greet(String, Int) -> String")]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="parameter-added")
}

///|
test "detects visibility tightening" {
  let old_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[String]\n}",
    ),
  ]
  let new_api = [
    api_item(
      "struct", "Report", "pub struct Report {\n  issues : Array[String]\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="visibility-tightened")
}

///|
test "detects struct field removal" {
  let old_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[String]\n  severity : String\n}",
    ),
  ]
  let new_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[String]\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="field-removed")
}

///|
test "detects struct field type change" {
  let old_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[String]\n}",
    ),
  ]
  let new_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[Int]\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="field-type-changed")
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
  inspect(items[1].signature.contains("issues : Array[String]"), content="true")
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
test "parses enum trait and fnalias declarations" {
  let items = parse_mbti_items([
    "pub(all) enum Status {", "  Ok", "  Error(String)", "}", "pub trait Formatter {",
    "  fn format(Self) -> String", "}", "pub fnalias run = parse",
  ])
  inspect(items.length(), content="3")
  inspect(items[0].kind, content="enum")
  inspect(items[0].name, content="Status")
  inspect(items[1].kind, content="trait")
  inspect(items[2].kind, content="fnalias")
  inspect(items[2].name, content="run")
}

///|
test "parses pkg generated style mbti content" {
  let content = "package \"FidollarinLA/moon_api_guard\"\n\npub fn compare_api(Array[ApiItem], Array[ApiItem]) -> ApiReport\n\npub(all) struct ApiChange {\n  category : String\n  detail : String\n  kind : String\n  name : String\n  message : String\n} derive(Eq, Debug)\n"
  let items = parse_mbti_content(content)
  inspect(items.length(), content="2")
  inspect(items[0].kind, content="fn")
  inspect(items[0].name, content="compare_api")
  inspect(items[1].kind, content="struct")
  inspect(items[1].signature.contains("detail : String"), content="true")
}

///|
test "compares fixture style api snapshots" {
  let old_content = "pub fn parse(String) -> Int\npub fn greet(String, Int) -> String\npub(all) struct Report {\n  issues : Array[String]\n  severity : String\n}\n"
  let new_content = "pub fn parse(String) -> String\npub fn greet(String) -> String\npub(all) struct Report {\n  issues : Array[String]\n}\n"
  let report = compare_api(
    parse_mbti_content(old_content),
    parse_mbti_content(new_content),
  )
  inspect(report.breaking_count(), content="3")
  inspect(report.release_blocked(), content="true")
  inspect(report.semver_suggestion(), content="major")
}

///|
test "treats enum variant addition as compatible" {
  let old_api = [
    api_item(
      "enum", "Status", "pub(all) enum Status {\n  Ok\n  Error(String)\n}",
    ),
  ]
  let new_api = [
    api_item(
      "enum", "Status", "pub(all) enum Status {\n  Ok\n  Error(String)\n  Warning\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="0")
  inspect(report.compatible_count(), content="1")
  inspect(report.changes[0].detail, content="variant-added")
}

///|
test "renders markdown report summary" {
  let report = compare_api(
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
    [api_item("fn", "parse", "pub fn parse(String) -> String")],
  )
  inspect(
    report.markdown_summary(),
    content="# moon_api_guard report\n\n- breaking: 1\n- compatible: 0\n- semver: major\n\n## Changes\n\n- kind: fn, name: parse, message: return type changed from Int to String",
  )
}

///|
test "blocks release when breaking changes exist" {
  let breaking_report = compare_api(
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
    [],
  )
  let compatible_report = compare_api([], [
    api_item("fn", "parse", "pub fn parse(String) -> Int"),
  ])
  inspect(breaking_report.release_blocked(), content="true")
  inspect(compatible_report.release_blocked(), content="false")
}

///|
test "renders json report summary" {
  let report = compare_api([], [
    api_item("fn", "parse", "pub fn parse(String) -> Int"),
  ])
  inspect(
    report.json_summary(),
    content="{\"breaking\":0,\"compatible\":1,\"semver\":\"minor\",\"release_blocked\":false,\"changes\":[{\"category\":\"compatible\",\"detail\":\"added\",\"kind\":\"fn\",\"name\":\"parse\",\"message\":\"fn parse was added\"}]}",
  )
}

///|
test "parses implementation declarations" {
  let items = parse_mbti_items([
    "impl Eq for ApiItem with op_equal(Self, Self) -> Bool",
  ])
  inspect(items.length(), content="1")
  inspect(items[0].kind, content="impl")
  inspect(items[0].name, content="Eq for ApiItem")
}

///|
test "detects trait method removal" {
  let old_api = [
    api_item(
      "trait", "Formatter", "pub trait Formatter {\n  fn format(Self) -> String\n  fn debug(Self) -> String\n}",
    ),
  ]
  let new_api = [
    api_item(
      "trait", "Formatter", "pub trait Formatter {\n  fn format(Self) -> String\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="method-removed")
}

///|
test "detects parameter type change" {
  let old_api = [api_item("fn", "greet", "pub fn greet(String, Int) -> String")]
  let new_api = [api_item("fn", "greet", "pub fn greet(Int, String) -> String")]
  let report = compare_api(old_api, new_api)
  inspect(report.changes[0].detail, content="parameter-changed")
}

///|
test "detects enum variant removal as breaking" {
  let old_api = [
    api_item(
      "enum", "Status", "pub(all) enum Status {\n  Ok\n  Error(String)\n}",
    ),
  ]
  let new_api = [api_item("enum", "Status", "pub(all) enum Status {\n  Ok\n}")]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="variant-removed")
}

///|
test "detects trait method change" {
  let old_api = [
    api_item(
      "trait", "Formatter", "pub trait Formatter {\n  fn format(Self) -> String\n}",
    ),
  ]
  let new_api = [
    api_item(
      "trait", "Formatter", "pub trait Formatter {\n  fn format(Self) -> Int\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.changes[0].detail, content="method-changed")
}

///|
test "detects trait method addition as breaking detail" {
  let old_api = [
    api_item(
      "trait", "Formatter", "pub trait Formatter {\n  fn format(Self) -> String\n}",
    ),
  ]
  let new_api = [
    api_item(
      "trait", "Formatter", "pub trait Formatter {\n  fn format(Self) -> String\n  fn debug(Self) -> String\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.changes[0].detail, content="method-added")
}

///|
test "detects struct field addition" {
  let old_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[String]\n}",
    ),
  ]
  let new_api = [
    api_item(
      "struct", "Report", "pub(all) struct Report {\n  issues : Array[String]\n  severity : String\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.changes[0].detail, content="field-added")
}

///|
test "detects alias signature change" {
  let old_api = [api_item("alias", "Name", "pub(all) typealias Name = String")]
  let new_api = [api_item("alias", "Name", "pub(all) typealias Name = Int")]
  let report = compare_api(old_api, new_api)
  inspect(report.changes[0].detail, content="signature-changed")
}

///|
test "parses attribute prefixed declarations" {
  let items = parse_mbti_items(["#deprecated", "pub fn count() -> Int"])
  inspect(items.length(), content="1")
  inspect(items[0].name, content="count")
}

///|
test "parses suberror const and associated function items" {
  let items = parse_mbti_items([
    "pub(all) suberror IOError {", "  IOError(String)", "}", "pub const VERSION : Int = 1",
    "pub fn ApiReport::count(Self) -> Int",
  ])
  inspect(items.length(), content="3")
  inspect(items[0].kind, content="suberror")
  inspect(items[1].kind, content="const")
  inspect(items[2].kind, content="fn")
  inspect(items[2].name, content="count")
}

///|
test "parses private visibility declarations" {
  let old_api = [api_item("type", "Decoder", "type Decoder")]
  let new_api = [api_item("type", "Decoder", "type Decoder")]
  let report = compare_api(old_api, new_api)
  inspect(report.semver_suggestion(), content="patch")
}

///|
test "parses impl without for clause" {
  let items = parse_mbti_items(["impl Show for ApiItem"])
  inspect(items[0].name, content="Show for ApiItem")
}

///|
test "parses impl with trait alias only" {
  let items = parse_mbti_items([
    "impl Eq for ApiItem with op_equal(Self, Self) -> Bool",
  ])
  inspect(items[0].name, content="Eq for ApiItem")
}

///|
test "parses bare trait declaration" {
  let items = parse_mbti_items(["trait Num {", "  fn abs(Self) -> Self", "}"])
  inspect(items[0].kind, content="trait")
  inspect(items[0].name, content="Num")
}

///|
test "parses single line struct declaration" {
  let items = parse_mbti_items(["pub(all) struct Point { x : Int }"])
  inspect(items[0].kind, content="struct")
}

///|
test "handles field names without colon" {
  let old_api = [
    api_item(
      "enum", "Status", "pub(all) enum Status {\n  Ok\n  Error(String)\n}",
    ),
  ]
  let new_api = [
    api_item("enum", "Status", "pub(all) enum Status {\n  Ok\n  Warning\n}"),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
}

///|
test "json string escapes special characters" {
  let change = api_change(
    "breaking", "removed", "fn", "say", "message with \"quotes\" and\nnewline",
  )
  inspect(
    change.json_object(),
    content="{\"category\":\"breaking\",\"detail\":\"removed\",\"kind\":\"fn\",\"name\":\"say\",\"message\":\"message with \\\"quotes\\\" and\\nnewline\"}",
  )
}

///|
test "change markdown line includes kind and name" {
  let change = api_change(
    "compatible", "added", "fn", "format", "fn format was added",
  )
  inspect(
    change.markdown_line(),
    content="- kind: fn, name: format, message: fn format was added",
  )
}

///|
test "json report joins multiple change objects" {
  let report = compare_api(
    [api_item("fn", "parse", "pub fn parse(String) -> Int")],
    [
      api_item("fn", "parse", "pub fn parse(String) -> String"),
      api_item("fn", "format", "pub fn format(Int) -> String"),
    ],
  )
  inspect(report.changes.length(), content="2")
  inspect(report.json_summary().contains("\"changes\":[{"), content="true")
  inspect(report.json_summary().contains("},{"), content="true")
}

///|
test "json string escapes backslashes" {
  let change = api_change(
    "breaking", "signature-changed", "type", "Path", "path\\to\\value",
  )
  inspect(change.json_object().contains("\\\\"), content="true")
}

///|
test "classifies zero parameter functions" {
  let old_api = [api_item("fn", "run", "pub fn run() -> Unit")]
  let new_api = [api_item("fn", "run", "pub fn run(Int) -> Unit")]
  let report = compare_api(old_api, new_api)
  inspect(report.changes[0].detail, content="parameter-added")
}

///|
test "classifies functions without return arrow" {
  let items = parse_mbti_items(["pub const FLAG : Bool = true"])
  inspect(items[0].kind, content="const")
}

///|
test "skips unrecognized public item lines" {
  let items = parse_mbti_items([
    "pub(all) struct Point { x : Int }", "not-a-public-item",
  ])
  inspect(items.length(), content="1")
}

///|
test "detects breaking enum variant replacement" {
  let old_api = [
    api_item(
      "enum", "Status", "pub(all) enum Status {\n  Ok\n  Error(String)\n}",
    ),
  ]
  let new_api = [
    api_item(
      "enum", "Status", "pub(all) enum Status {\n  Ok\n  Failed(String)\n}",
    ),
  ]
  let report = compare_api(old_api, new_api)
  inspect(report.breaking_count(), content="1")
  inspect(report.changes[0].detail, content="variant-removed")
}

///|
test "parses type alias declarations" {
  let items = parse_mbti_items([
    "pub typealias Handler = Decoder", "type Decoder",
  ])
  inspect(items.length(), content="1")
  inspect(items[0].kind, content="alias")
}

///|
test "parses method style function names from traits" {
  let items = parse_mbti_items([
    "pub trait Writer {", "  pub fn write(Self, String) -> Unit", "}",
  ])
  inspect(items[0].kind, content="trait")
}
