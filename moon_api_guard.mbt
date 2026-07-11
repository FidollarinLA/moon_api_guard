///|
/// A public API item extracted from a MoonBit interface file.
pub(all) struct ApiItem {
  kind : String
  name : String
  signature : String
} derive(Eq, Debug)

///|
/// A single compatibility finding between two API snapshots.
pub(all) struct ApiChange {
  category : String
  kind : String
  name : String
  message : String
} derive(Eq, Debug)

///|
/// Compatibility report for one old/new API comparison.
pub(all) struct ApiReport {
  changes : Array[ApiChange]
} derive(Debug)

///|
/// Create a normalized public API item.
pub fn api_item(kind : String, name : String, signature : String) -> ApiItem {
  { kind, name, signature }
}

///|
/// Compare two public API snapshots.
pub fn compare_api(
  old_items : Array[ApiItem],
  new_items : Array[ApiItem],
) -> ApiReport {
  let changes : Array[ApiChange] = []
  for old_item in old_items {
    match find_item(new_items, old_item.kind, old_item.name) {
      None =>
        changes.push(
          api_change(
            "breaking",
            old_item.kind,
            old_item.name,
            "\{old_item.kind} \{old_item.name} was removed",
          ),
        )
      Some(new_item) =>
        if old_item.signature != new_item.signature {
          changes.push(
            api_change(
              "breaking",
              old_item.kind,
              old_item.name,
              "\{old_item.kind} \{old_item.name} changed signature",
            ),
          )
        }
    }
  }
  for new_item in new_items {
    if find_item(old_items, new_item.kind, new_item.name) is None {
      changes.push(
        api_change(
          "compatible",
          new_item.kind,
          new_item.name,
          "\{new_item.kind} \{new_item.name} was added",
        ),
      )
    }
  }
  { changes, }
}

///|
/// Parse a small, stable subset of `.mbti` public interface lines.
pub fn parse_mbti_items(lines : Array[String]) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  for line in lines {
    match parse_mbti_line(line) {
      Some(item) => items.push(item)
      None => ()
    }
  }
  items
}

///|
/// Count breaking changes.
pub fn ApiReport::breaking_count(self : ApiReport) -> Int {
  self.count_category("breaking")
}

///|
/// Count compatible additions.
pub fn ApiReport::compatible_count(self : ApiReport) -> Int {
  self.count_category("compatible")
}

///|
/// Suggest the smallest SemVer bump implied by the report.
pub fn ApiReport::semver_suggestion(self : ApiReport) -> String {
  if self.breaking_count() > 0 {
    "major"
  } else if self.compatible_count() > 0 {
    "minor"
  } else {
    "patch"
  }
}

///|
fn ApiReport::count_category(self : ApiReport, category : String) -> Int {
  let mut count = 0
  for change in self.changes {
    if change.category == category {
      count = count + 1
    }
  }
  count
}

///|
fn api_change(
  category : String,
  kind : String,
  name : String,
  message : String,
) -> ApiChange {
  { category, kind, name, message }
}

///|
fn find_item(items : Array[ApiItem], kind : String, name : String) -> ApiItem? {
  for item in items {
    if item.kind == kind && item.name == name {
      return Some(item)
    }
  }
  None
}

///|
fn parse_mbti_line(line : String) -> ApiItem? {
  if line.contains("pub fn ") {
    Some(api_item("fn", name_after(line, "pub fn "), line))
  } else if line.contains("pub(all) struct ") {
    Some(api_item("struct", name_after(line, "pub(all) struct "), line))
  } else if line.contains("pub(all) enum ") {
    Some(api_item("enum", name_after(line, "pub(all) enum "), line))
  } else if line.contains("pub trait ") {
    Some(api_item("trait", name_after(line, "pub trait "), line))
  } else if line.contains("pub typealias ") {
    Some(api_item("alias", name_after(line, "pub typealias "), line))
  } else {
    None
  }
}

///|
fn name_after(line : String, prefix : String) -> String {
  match line.split_once(prefix) {
    Some((_, rest)) => first_identifier(rest.to_owned())
    None => ""
  }
}

///|
fn first_identifier(text : String) -> String {
  let mut result = ""
  for char in text {
    if is_identifier_char(char) {
      result = result + char.to_string()
    } else {
      return result
    }
  }
  result
}

///|
fn is_identifier_char(char : Char) -> Bool {
  (char >= 'a' && char <= 'z') ||
  (char >= 'A' && char <= 'Z') ||
  (char >= '0' && char <= '9') ||
  char == '_' ||
  char == ':'
}
