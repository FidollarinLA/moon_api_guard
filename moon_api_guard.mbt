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
  detail : String
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
/// Parse `.mbti` file content into normalized public API items.
pub fn parse_mbti_content(content : String) -> Array[ApiItem] {
  let lines : Array[String] = []
  for line in content.split("\n") {
    lines.push(owned(line))
  }
  parse_mbti_items(lines)
}

///|
/// Parse `.mbti` interface lines into normalized public API items.
pub fn parse_mbti_items(lines : Array[String]) -> Array[ApiItem] {
  let items : Array[ApiItem] = []
  let mut index = 0
  let mut pending_attrs = ""
  while index < lines.length() {
    let raw = lines[index]
    let line = trim_line(raw)
    if line.length() == 0 ||
      line.has_prefix("//") ||
      line.has_prefix("import ") ||
      line.has_prefix("package ") {
      index = index + 1
      continue
    }
    if line.has_prefix("#") {
      pending_attrs = append_line(pending_attrs, line)
      index = index + 1
      continue
    }
    if is_block_start(line) {
      let (block, next_index) = read_block(lines, index)
      let signature = append_line(pending_attrs, block)
      pending_attrs = ""
      match item_from_signature(signature) {
        Some(item) => items.push(item)
        None => ()
      }
      index = next_index
    } else if is_public_item_line(line) {
      let signature = append_line(pending_attrs, line)
      pending_attrs = ""
      match item_from_signature(signature) {
        Some(item) => items.push(item)
        None => ()
      }
      index = index + 1
    } else {
      pending_attrs = ""
      index = index + 1
    }
  }
  items
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
            "removed",
            old_item.kind,
            old_item.name,
            "\{old_item.kind} \{old_item.name} was removed",
          ),
        )
      Some(new_item) =>
        if old_item.signature != new_item.signature {
          let classification = classify_item_change(
            old_item.kind,
            old_item.signature,
            new_item.signature,
          )
          changes.push(
            api_change(
              classification.category,
              classification.detail,
              old_item.kind,
              old_item.name,
              classification.message,
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
          "added",
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
pub fn ApiReport::markdown_summary(self : ApiReport) -> String {
  let mut summary = "# moon_api_guard report\n\n- breaking: \{self.breaking_count()}\n- compatible: \{self.compatible_count()}\n- semver: \{self.semver_suggestion()}"
  if self.changes.length() > 0 {
    summary = summary + "\n\n## Changes\n"
    for change in self.changes {
      summary = summary +
        "\n- [\{change.category}/\{change.detail}] \{change.message}"
    }
  }
  summary
}

///|
pub fn ApiReport::release_blocked(self : ApiReport) -> Bool {
  self.breaking_count() > 0
}

///|
pub fn ApiReport::json_summary(self : ApiReport) -> String {
  "{\"breaking\":\{self.breaking_count()},\"compatible\":\{self.compatible_count()},\"semver\":\"\{self.semver_suggestion()}\",\"release_blocked\":\{self.release_blocked()}}"
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
  detail : String,
  kind : String,
  name : String,
  message : String,
) -> ApiChange {
  { category, detail, kind, name, message }
}

///|
fn append_line(existing : String, line : String) -> String {
  if existing.length() == 0 {
    line
  } else {
    existing + "\n" + line
  }
}

///|
fn brace_delta(line : String) -> Int {
  let mut delta = 0
  for char in line {
    if char == '{' {
      delta = delta + 1
    } else if char == '}' {
      delta = delta - 1
    }
  }
  delta
}

///|
priv struct ChangeClassification {
  category : String
  detail : String
  message : String
}

///|
fn owned(text : StringView) -> String {
  text.to_owned()
}

///|
fn classify_item_change(
  kind : String,
  old_signature : String,
  new_signature : String,
) -> ChangeClassification {
  if kind == "enum" && is_enum_additive_only(old_signature, new_signature) {
    {
      category: "compatible",
      detail: "variant-added",
      message: "enum variant added",
    }
  } else {
    let (detail, message) = classify_signature_change(
      kind, old_signature, new_signature,
    )
    { category: "breaking", detail, message }
  }
}

///|
fn is_enum_additive_only(
  old_signature : String,
  new_signature : String,
) -> Bool {
  let old_variants = body_fields(old_signature)
  let new_variants = body_fields(new_signature)
  for old_variant in old_variants {
    if !contains_field(new_variants, old_variant) {
      return false
    }
  }
  old_variants.length() != new_variants.length()
}

///|
fn classify_signature_change(
  kind : String,
  old_signature : String,
  new_signature : String,
) -> (String, String) {
  if visibility_tightened(old_signature, new_signature) {
    (
      "visibility-tightened",
      "\{kind} visibility tightened from pub(all) to pub",
    )
  } else if kind == "fn" || kind == "fnalias" {
    classify_function_change(old_signature, new_signature)
  } else if kind == "struct" || kind == "suberror" {
    classify_fielded_change(kind, old_signature, new_signature)
  } else if kind == "enum" {
    classify_variant_change(kind, old_signature, new_signature)
  } else if kind == "trait" {
    classify_trait_change(old_signature, new_signature)
  } else {
    ("signature-changed", "\{kind} signature changed")
  }
}

///|
fn classify_fielded_change(
  kind : String,
  old_signature : String,
  new_signature : String,
) -> (String, String) {
  let old_fields = body_fields(old_signature)
  let new_fields = body_fields(new_signature)
  for old_field in old_fields {
    let old_name = field_name(old_field)
    match find_field_by_name(new_fields, old_name) {
      None => return ("field-removed", "\{kind} field removed: \{old_field}")
      Some(new_field) =>
        if new_field != old_field {
          return (
            "field-type-changed",
            "\{kind} field type changed: \{old_name}",
          )
        }
    }
  }
  for new_field in new_fields {
    let new_name = field_name(new_field)
    if find_field_by_name(old_fields, new_name) is None {
      return ("field-added", "\{kind} field added: \{new_field}")
    }
  }
  ("signature-changed", "\{kind} signature changed")
}

///|
fn find_field_by_name(fields : Array[String], target_name : String) -> String? {
  for field in fields {
    if field_name(field) == target_name {
      return Some(field)
    }
  }
  None
}

///|
fn classify_function_change(
  old_signature : String,
  new_signature : String,
) -> (String, String) {
  let old_return = function_return_type(old_signature)
  let new_return = function_return_type(new_signature)
  if old_return != new_return &&
    old_return.length() > 0 &&
    new_return.length() > 0 {
    return (
      "return-type-changed",
      "return type changed from \{old_return} to \{new_return}",
    )
  }
  let old_params = function_params(old_signature)
  let new_params = function_params(new_signature)
  let old_count = count_params(old_params)
  let new_count = count_params(new_params)
  if new_count < old_count {
    return ("parameter-removed", "function parameter removed")
  }
  if new_count > old_count {
    return ("parameter-added", "function parameter added")
  }
  if old_params != new_params {
    return ("parameter-changed", "function parameter changed")
  }
  ("signature-changed", "function signature changed")
}

///|
fn classify_trait_change(
  old_signature : String,
  new_signature : String,
) -> (String, String) {
  let old_methods = body_fields(old_signature)
  let new_methods = body_fields(new_signature)
  for old_method in old_methods {
    if !contains_field(new_methods, old_method) {
      return ("method-removed", "trait method removed: \{old_method}")
    }
  }
  for new_method in new_methods {
    if !contains_field(old_methods, new_method) {
      return ("method-added", "trait method added: \{new_method}")
    }
  }
  for old_method in old_methods {
    let old_name = field_name(old_method)
    for new_method in new_methods {
      if field_name(new_method) == old_name && new_method != old_method {
        return ("method-changed", "trait method changed: \{old_name}")
      }
    }
  }
  ("signature-changed", "trait signature changed")
}

///|
fn classify_variant_change(
  kind : String,
  old_signature : String,
  new_signature : String,
) -> (String, String) {
  let old_variants = body_fields(old_signature)
  let new_variants = body_fields(new_signature)
  for old_variant in old_variants {
    if !contains_field(new_variants, old_variant) {
      return ("variant-removed", "\{kind} variant removed: \{old_variant}")
    }
  }
  for new_variant in new_variants {
    if !contains_field(old_variants, new_variant) {
      return ("variant-added", "\{kind} variant added: \{new_variant}")
    }
  }
  ("signature-changed", "\{kind} signature changed")
}

///|
fn contains_field(fields : Array[String], target : String) -> Bool {
  for field in fields {
    if field == target {
      return true
    }
  }
  false
}

///|
fn count_params(params : String) -> Int {
  if params.length() == 0 {
    0
  } else {
    let mut count = 1
    let mut depth = 0
    for char in params {
      if char == '(' || char == '[' {
        depth = depth + 1
      } else if char == ')' || char == ']' {
        depth = depth - 1
      } else if char == ',' && depth == 0 {
        count = count + 1
      }
    }
    count
  }
}

///|
fn extract_brace_body(signature : String) -> String {
  match signature.split_once("{") {
    Some((_, after_open)) => {
      let mut body = ""
      let mut depth = 1
      for char in after_open {
        if char == '{' {
          depth = depth + 1
          body = body + char.to_string()
        } else if char == '}' {
          depth = depth - 1
          if depth == 0 {
            return body
          } else {
            body = body + char.to_string()
          }
        } else {
          body = body + char.to_string()
        }
      }
      body
    }
    None => ""
  }
}

///|
fn body_fields(signature : String) -> Array[String] {
  let body = extract_brace_body(signature)
  let fields : Array[String] = []
  for line in body.split("\n") {
    let trimmed = trim_line(owned(line))
    if trimmed.length() > 0 &&
      !trimmed.has_prefix("//") &&
      !trimmed.has_prefix("derive(") &&
      !trimmed.has_prefix("#") {
      if trimmed.contains(":") || is_trait_method_line(trimmed) {
        fields.push(trimmed)
      } else if trimmed.has_suffix(")") || is_variant_name(trimmed) {
        fields.push(trimmed)
      }
    }
  }
  fields
}

///|
fn field_name(field : String) -> String {
  if field.contains(":") {
    match field.split_once(":") {
      Some((name, _)) => trim_line(owned(name))
      None => field
    }
  } else {
    trim_line(field)
  }
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
fn function_params(signature : String) -> String {
  let head = function_head(signature)
  match head.split_once("(") {
    Some((_, after_open)) => {
      let mut params = ""
      let mut depth = 0
      for char in after_open {
        if char == '(' || char == '[' {
          depth = depth + 1
          params = params + char.to_string()
        } else if char == ')' || char == ']' {
          if depth == 0 {
            return trim_line(params)
          }
          depth = depth - 1
          params = params + char.to_string()
        } else {
          params = params + char.to_string()
        }
      }
      trim_line(params)
    }
    None => ""
  }
}

///|
fn function_head(signature : String) -> String {
  match signature.split_once("->") {
    Some((before, _)) => trim_line(owned(before))
    None => trim_line(signature)
  }
}

///|
fn function_return_type(signature : String) -> String {
  let parts : Array[String] = []
  for part in signature.split("->") {
    parts.push(owned(part))
  }
  if parts.length() <= 1 {
    ""
  } else {
    trim_line(parts[parts.length() - 1])
  }
}

///|
fn is_block_start(line : String) -> Bool {
  line.contains(" struct ") ||
  line.contains(" enum ") ||
  line.contains(" suberror ") ||
  line.has_prefix("pub trait ") ||
  line.has_prefix("trait ")
}

///|
fn is_public_item_line(line : String) -> Bool {
  line.has_prefix("pub fn ") ||
  line.has_prefix("pub fnalias ") ||
  line.has_prefix("pub(all) fnalias ") ||
  line.has_prefix("pub type ") ||
  line.has_prefix("pub(all) type ") ||
  line.has_prefix("pub typealias ") ||
  line.has_prefix("pub(all) typealias ") ||
  line.has_prefix("pub const ") ||
  line.has_prefix("pub impl ") ||
  line.has_prefix("impl ") ||
  line.has_prefix("pub(all) struct ") ||
  line.has_prefix("pub(all) enum ") ||
  line.has_prefix("pub(all) suberror ") ||
  (
    !line.has_prefix("pub fn ") &&
    line.contains("::") &&
    line.contains("(") &&
    line.contains("->")
  )
}

///|
fn is_trait_method_line(line : String) -> Bool {
  line.has_prefix("fn ") || line.has_prefix("pub fn ")
}

///|
fn is_variant_name(line : String) -> Bool {
  let trimmed = trim_line(line)
  trimmed.length() > 0 &&
  !trimmed.contains(" ") &&
  !trimmed.contains(":") &&
  !trimmed.contains("(")
}

///|
fn item_from_signature(signature : String) -> ApiItem? {
  let first_line = first_line_of(signature)
  if first_line.contains(" struct ") {
    Some(
      api_item("struct", name_after_keyword(signature, " struct "), signature),
    )
  } else if first_line.contains(" enum ") {
    Some(api_item("enum", name_after_keyword(signature, " enum "), signature))
  } else if first_line.contains(" suberror ") {
    Some(
      api_item(
        "suberror",
        name_after_keyword(signature, " suberror "),
        signature,
      ),
    )
  } else if first_line.has_prefix("pub trait ") {
    Some(
      api_item("trait", name_after_keyword(signature, "pub trait "), signature),
    )
  } else if first_line.has_prefix("trait ") {
    Some(api_item("trait", name_after_keyword(signature, "trait "), signature))
  } else if first_line.contains("fnalias ") {
    Some(api_item("fnalias", name_after_fnalias(signature), signature))
  } else if first_line.contains("pub fn ") || first_line.contains("::") {
    Some(api_item("fn", name_after_function(signature), signature))
  } else if first_line.contains(" typealias ") {
    Some(
      api_item("alias", name_after_keyword(signature, " typealias "), signature),
    )
  } else if first_line.contains(" type ") {
    Some(api_item("type", name_after_keyword(signature, " type "), signature))
  } else if first_line.has_prefix("pub const ") {
    Some(
      api_item("const", name_after_keyword(signature, "pub const "), signature),
    )
  } else if first_line.has_prefix("pub impl ") || first_line.has_prefix("impl ") {
    Some(api_item("impl", name_after_impl(signature), signature))
  } else {
    None
  }
}

///|
fn first_line_of(text : String) -> String {
  match text.split_once("\n") {
    Some((first, _)) => trim_line(owned(first))
    None => trim_line(text)
  }
}

///|
fn name_after_fnalias(signature : String) -> String {
  let line = first_line_of(signature)
  if line.contains("fnalias ") {
    name_after(line, "fnalias ")
  } else {
    ""
  }
}

///|
fn name_after_function(signature : String) -> String {
  let line = first_line_of(signature)
  if line.contains("::") {
    match line.split_once("::") {
      Some((_, rest)) => first_identifier(trim_line(owned(rest)))
      None => ""
    }
  } else if line.contains("pub fn ") {
    name_after(line, "pub fn ")
  } else if line.contains("fn ") {
    name_after(line, "fn ")
  } else {
    ""
  }
}

///|
fn name_after_impl(signature : String) -> String {
  let line = first_line_of(signature)
  match line.split_once(" for ") {
    Some((head, tail)) => {
      let impl_part = trim_line(owned(head))
      let trait_part = name_after(impl_part, "impl ")
      let trait_name = match trait_part.split_once(" with ") {
        Some((before, _)) => trim_line(owned(before))
        None => trait_part
      }
      let type_name = first_identifier(trim_line(owned(tail)))
      if type_name.length() > 0 {
        "\{trait_name} for \{type_name}"
      } else {
        trait_name
      }
    }
    None => first_identifier(name_after(line, "impl "))
  }
}

///|
fn name_after(text : String, prefix : String) -> String {
  match text.split_once(prefix) {
    Some((_, rest)) => first_identifier(trim_line(owned(rest)))
    None => ""
  }
}

///|
fn name_after_keyword(signature : String, keyword : String) -> String {
  name_after(first_line_of(signature), keyword)
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

///|
fn read_block(lines : Array[String], start : Int) -> (String, Int) {
  let mut index = start
  let mut block = ""
  let mut depth = 0
  while index < lines.length() {
    let line = lines[index]
    block = append_line(block, line)
    depth = depth + brace_delta(line)
    index = index + 1
    if depth <= 0 && line.contains("}") {
      break
    }
  }
  (block, index)
}

///|
fn trim_line(line : String) -> String {
  line.trim(char_set=" \t\r").to_owned()
}

///|
fn visibility_level(signature : String) -> Int {
  if signature.contains("pub(all)") {
    3
  } else if signature.contains("pub ") || signature.has_prefix("pub") {
    2
  } else {
    1
  }
}

///|
fn visibility_tightened(old_signature : String, new_signature : String) -> Bool {
  visibility_level(new_signature) < visibility_level(old_signature)
}
