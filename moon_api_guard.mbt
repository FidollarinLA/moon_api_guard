///|
/// A public API item extracted from a MoonBit interface file.
///
/// - `kind` is the item category, such as `fn`, `struct`, `enum`,
///   `trait`, `type`, `alias`, `fnalias`, `const`, `suberror`, or `impl`.
/// - `name` is the normalized item name used to match old and new snapshots.
/// - `signature` is the full declaration text, including a multi-line body
///   for structs, enums, suberrors, and traits.
pub(all) struct ApiItem {
  kind : String
  name : String
  signature : String
} derive(Eq, Debug)

///|
/// A single compatibility finding between two API snapshots.
///
/// - `category` is `"breaking"` or `"compatible"`.
/// - `detail` is a machine-readable reason, such as `removed`,
///   `return-type-changed`, `parameter-removed`, `visibility-tightened`,
///   `field-removed`, `method-changed`, or `variant-added`.
/// - `kind` / `name` identify the affected API item.
/// - `message` is a human-readable explanation for reports.
pub(all) struct ApiChange {
  category : String
  detail : String
  kind : String
  name : String
  message : String
} derive(Eq, Debug)

///|
/// Compatibility report for one old/new API comparison.
///
/// Wraps the list of findings and derives release signals from it:
/// breaking/compatible counts, a SemVer suggestion, a release blocking
/// flag for CI, and Markdown/JSON summaries.
pub(all) struct ApiReport {
  changes : Array[ApiChange]
} derive(Debug)

///|
/// Create a normalized public API item.
///
/// Example:
///
/// ```mbt nocheck
/// let item = api_item("fn", "parse", "pub fn parse(String) -> Int")
/// ```
pub fn api_item(kind : String, name : String, signature : String) -> ApiItem {
  { kind, name, signature }
}

///|
/// Parse the full text of a `.mbti` file (as produced by `moon info`)
/// into normalized public API items.
///
/// This is the most convenient entry point when the caller has already
/// read an interface file into a string.
pub fn parse_mbti_content(content : String) -> Array[ApiItem] {
  let lines : Array[String] = []
  for line in content.split("\n") {
    lines.push(owned(line))
  }
  parse_mbti_items(lines)
}

///|
/// Parse `.mbti` interface lines into normalized public API items.
///
/// Supported declarations include functions, associated functions
/// (`Type::method`), `fnalias`, `typealias`, `type`, `const`, `impl`,
/// and multi-line `struct` / `enum` / `suberror` / `trait` blocks.
/// Comment lines, `package` / `import` headers, and unknown lines are
/// skipped. Attribute lines starting with `#` (such as `#deprecated`)
/// are attached to the declaration that follows them.
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
/// Compare two public API snapshots and produce a compatibility report.
///
/// Classification rules:
/// - An item present in `old_items` but missing in `new_items` is a
///   breaking `removed` change.
/// - An item present in both but with a different signature is classified
///   further (return type, parameters, visibility, fields, methods,
///   variants). Enum variant additions are breaking because exhaustive
///   pattern matching in downstream code may no longer compile.
/// - An item only present in `new_items` is a compatible `added` change.
/// - Marking an existing item with `#deprecated` (body unchanged) is a
///   compatible `deprecated` change.
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
/// Parse and compare two `.mbti` file contents in one step.
///
/// This is the most convenient library entry when callers already have
/// old/new interface text and do not need intermediate `ApiItem` lists.
///
/// Example:
///
/// ```mbt nocheck
/// let report = compare_mbti_content(old_mbti, new_mbti)
/// assert_eq(report.semver_suggestion(), "major")
/// ```
pub fn compare_mbti_content(
  old_content : String,
  new_content : String,
) -> ApiReport {
  compare_api(parse_mbti_content(old_content), parse_mbti_content(new_content))
}

///|
/// Keep only breaking changes. Useful for CI summaries that should ignore
/// compatible additions.
pub fn ApiReport::breaking_only(self : ApiReport) -> ApiReport {
  let changes : Array[ApiChange] = []
  for change in self.changes {
    if change.category == "breaking" {
      changes.push(change)
    }
  }
  { changes, }
}

///|
/// Prefix every change name with `scope::` so multi-file reports remain
/// attributable to a concrete `.mbti` path.
pub fn ApiReport::scoped(self : ApiReport, scope : String) -> ApiReport {
  let changes : Array[ApiChange] = []
  for change in self.changes {
    changes.push(
      api_change(
        change.category,
        change.detail,
        change.kind,
        "\{scope}::\{change.name}",
        "\{scope}: \{change.message}",
      ),
    )
  }
  { changes, }
}

///|
/// Merge multiple reports into one by concatenating their changes.
pub fn merge_api_reports(reports : Array[ApiReport]) -> ApiReport {
  let changes : Array[ApiChange] = []
  for report in reports {
    for change in report.changes {
      changes.push(change)
    }
  }
  { changes, }
}

///|
/// Breaking report for a `.mbti` file present in the old snapshot but
/// missing from the new one.
pub fn file_removed_report(path : String) -> ApiReport {
  {
    changes: [
      api_change(
        "breaking",
        "file-removed",
        "file",
        path,
        "mbti file \{path} was removed",
      ),
    ],
  }
}

///|
/// Compatible report for a `.mbti` file present only in the new snapshot.
pub fn file_added_report(path : String) -> ApiReport {
  {
    changes: [
      api_change(
        "compatible",
        "file-added",
        "file",
        path,
        "mbti file \{path} was added",
      ),
    ],
  }
}

///|
/// Count breaking changes in the report.
pub fn ApiReport::breaking_count(self : ApiReport) -> Int {
  self.count_category("breaking")
}

///|
/// Count compatible changes (additions only).
pub fn ApiReport::compatible_count(self : ApiReport) -> Int {
  self.count_category("compatible")
}

///|
/// Suggest the smallest SemVer bump implied by the report:
/// `"major"` when any breaking change exists, `"minor"` when only
/// compatible changes exist, and `"patch"` when nothing changed.
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
/// Render one change as a Markdown list line with its kind, name,
/// and human-readable message.
pub fn ApiChange::markdown_line(self : ApiChange) -> String {
  "- kind: \{self.kind}, name: \{self.name}, message: \{self.message}"
}

///|
/// Render one change as a JSON object with `category`, `detail`,
/// `kind`, `name`, and `message` fields. String values are escaped.
pub fn ApiChange::json_object(self : ApiChange) -> String {
  "{" +
  "\"category\":" +
  json_string(self.category) +
  ",\"detail\":" +
  json_string(self.detail) +
  ",\"kind\":" +
  json_string(self.kind) +
  ",\"name\":" +
  json_string(self.name) +
  ",\"message\":" +
  json_string(self.message) +
  "}"
}

///|
/// Render the report as a Markdown document: a summary header with
/// breaking/compatible counts and the SemVer suggestion, followed by a
/// `## Changes` section listing every change when any exist.
pub fn ApiReport::markdown_summary(self : ApiReport) -> String {
  let mut summary = "# moon_api_guard report\n\n- breaking: \{self.breaking_count()}\n- compatible: \{self.compatible_count()}\n- semver: \{self.semver_suggestion()}"
  if self.changes.length() > 0 {
    summary = summary + "\n\n## Changes\n"
    for change in self.changes {
      summary = summary + "\n" + change.markdown_line()
    }
  }
  summary
}

///|
/// Whether a release should be blocked in CI. Returns `true` when the
/// report contains at least one breaking change.
pub fn ApiReport::release_blocked(self : ApiReport) -> Bool {
  self.breaking_count() > 0
}

///|
/// Render the report as a single-line JSON object for CI consumption.
/// The output contains `breaking`, `compatible`, `semver`,
/// `release_blocked`, and a `changes` array of per-change objects.
pub fn ApiReport::json_summary(self : ApiReport) -> String {
  let change_objects : Array[String] = []
  for change in self.changes {
    change_objects.push(change.json_object())
  }
  "{" +
  "\"breaking\":" +
  self.breaking_count().to_string() +
  ",\"compatible\":" +
  self.compatible_count().to_string() +
  ",\"semver\":" +
  json_string(self.semver_suggestion()) +
  ",\"release_blocked\":" +
  json_bool(self.release_blocked()) +
  ",\"changes\":" +
  json_array(change_objects) +
  "}"
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
fn json_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn json_array(items : Array[String]) -> String {
  let mut result = "["
  let mut first = true
  for item in items {
    if !first {
      result = result + ","
    }
    result = result + item
    first = false
  }
  result + "]"
}

///|
fn json_string(text : String) -> String {
  let mut result = "\""
  for char in text {
    if char == '"' {
      result = result + "\\\""
    } else if char == '\\' {
      result = result + "\\\\"
    } else if char == '\n' {
      result = result + "\\n"
    } else {
      result = result + char.to_string()
    }
  }
  result + "\""
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
/// Net change in brace nesting depth contributed by one line.
/// Used to find where a multi-line declaration block ends.
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
/// Internal result of classifying one signature difference.
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
/// Decide whether a signature difference is breaking or compatible.
/// Attribute-only `#deprecated` additions are compatible; all other
/// signature body differences are breaking.
fn classify_item_change(
  kind : String,
  old_signature : String,
  new_signature : String,
) -> ChangeClassification {
  let old_body = declaration_body(old_signature)
  let new_body = declaration_body(new_signature)
  if old_body == new_body {
    if became_deprecated(old_signature, new_signature) {
      {
        category: "compatible",
        detail: "deprecated",
        message: "\{kind} marked as deprecated",
      }
    } else {
      {
        category: "compatible",
        detail: "attribute-changed",
        message: "\{kind} attributes changed",
      }
    }
  } else {
    let (detail, message) = classify_signature_change(kind, old_body, new_body)
    { category: "breaking", detail, message }
  }
}

///|
/// Whether `#deprecated` appears on the new signature but not the old one.
fn became_deprecated(old_signature : String, new_signature : String) -> Bool {
  !has_deprecated_attr(old_signature) && has_deprecated_attr(new_signature)
}

///|
fn has_deprecated_attr(signature : String) -> Bool {
  for line in signature.split("\n") {
    let trimmed = trim_line(owned(line))
    if trimmed.has_prefix("#deprecated") {
      return true
    }
  }
  false
}

///|
/// Strip leading attribute lines (`#...`) so body-only diffs can be
/// classified separately from deprecation metadata changes.
fn declaration_body(signature : String) -> String {
  let mut body = ""
  let mut started = false
  for line in signature.split("\n") {
    let trimmed = trim_line(owned(line))
    if !started && trimmed.has_prefix("#") {
      continue
    }
    started = true
    body = append_line(body, trimmed)
  }
  body
}

///|
/// Dispatch a breaking signature difference to a kind-specific
/// classifier and return the `(detail, message)` pair. Visibility
/// tightening (`pub(all)` -> `pub`) wins over all other rules.
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
/// Classify struct / suberror body differences by comparing fields by
/// name: removed field, changed field type, then added field.
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
/// Classify function signature differences: return type first, then
/// parameter count (removed/added), then parameter text changes.
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
/// Classify trait body differences by comparing methods by name.
/// Any method removal, change, or addition is breaking, because
/// downstream `impl` blocks must match the trait exactly.
fn classify_trait_change(
  old_signature : String,
  new_signature : String,
) -> (String, String) {
  let old_methods = body_fields(old_signature)
  let new_methods = body_fields(new_signature)
  for old_method in old_methods {
    let old_name = field_name(old_method)
    match find_field_by_name(new_methods, old_name) {
      None => return ("method-removed", "trait method removed: \{old_method}")
      Some(new_method) =>
        if new_method != old_method {
          return ("method-changed", "trait method changed: \{old_name}")
        }
    }
  }
  for new_method in new_methods {
    let new_name = field_name(new_method)
    if find_field_by_name(old_methods, new_name) is None {
      return ("method-added", "trait method added: \{new_method}")
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
/// Count top-level parameters in a parameter list, ignoring commas
/// nested inside `(...)` or `[...]` such as tuple or generic arguments.
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
/// Extract the text between the first `{` and its matching `}`,
/// tracking nested braces. Returns an empty string for single-line
/// declarations without a body.
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
/// Collect meaningful body lines of a block declaration: struct fields,
/// enum variants, and trait methods. Comments, `derive(...)` clauses,
/// and attribute lines are skipped.
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
/// Extract the comparable name of a body line: the method name for
/// `fn ...` lines, the field name before `:` for struct fields, or the
/// whole trimmed line for enum variants.
fn field_name(field : String) -> String {
  if field.has_prefix("pub fn ") {
    name_after(field, "pub fn ")
  } else if field.has_prefix("fn ") {
    name_after(field, "fn ")
  } else if field.contains(":") {
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
/// Extract the raw parameter list text between the outermost `(` and
/// `)` of a function head, keeping nested brackets intact.
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
/// Extract the return type: the text after the last `->`, so nested
/// function types in parameters do not confuse the result.
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
/// Whether this line starts a multi-line block declaration that should
/// be read until its closing brace.
fn is_block_start(line : String) -> Bool {
  line.contains(" struct ") ||
  line.contains(" enum ") ||
  line.contains(" suberror ") ||
  line.has_prefix("pub trait ") ||
  line.has_prefix("trait ")
}

///|
/// Whether this single line declares a public API item worth tracking.
/// The final clause accepts associated-function lines like
/// `Type::method(...) -> T` that appear without a `pub fn` prefix.
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
/// Map one declaration (single line or multi-line block, possibly with
/// leading attribute lines) to a normalized `ApiItem`. Returns `None`
/// for lines that are not recognized public declarations.
fn item_from_signature(signature : String) -> ApiItem? {
  let first_line = declaration_line(signature)
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
/// The first non-empty, non-attribute line of a signature: the line
/// that actually carries the declaration keyword and name.
fn declaration_line(signature : String) -> String {
  for line in signature.split("\n") {
    let trimmed = trim_line(owned(line))
    if trimmed.length() > 0 && !trimmed.has_prefix("#") {
      return trimmed
    }
  }
  ""
}

///|
fn name_after_fnalias(signature : String) -> String {
  let line = declaration_line(signature)
  if line.contains("fnalias ") {
    name_after(line, "fnalias ")
  } else {
    ""
  }
}

///|
fn name_after_function(signature : String) -> String {
  let line = declaration_line(signature)
  if line.contains("::") {
    match line.split_once("::") {
      Some((type_part, rest)) => {
        let type_name = associated_type_name(trim_line(owned(type_part)))
        let method_name = first_identifier(trim_line(owned(rest)))
        if type_name.length() > 0 {
          "\{type_name}::\{method_name}"
        } else {
          method_name
        }
      }
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
/// Build the identity of an `impl` item as `"Trait for Type"` so the
/// same trait implemented for different types compares independently.
fn name_after_impl(signature : String) -> String {
  let line = declaration_line(signature)
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
/// Extract the receiver type name from the part before `::` in an
/// associated function declaration such as `pub fn ApiReport::count`
/// or `pub fn Map[K, V]::get`.
fn associated_type_name(type_part : String) -> String {
  let after_fn = if type_part.contains("pub fn ") {
    match type_part.split_once("pub fn ") {
      Some((_, rest)) => trim_line(owned(rest))
      None => type_part
    }
  } else if type_part.contains("fn ") {
    match type_part.split_once("fn ") {
      Some((_, rest)) => trim_line(owned(rest))
      None => type_part
    }
  } else {
    type_part
  }
  type_name_with_generics(after_fn)
}

///|
/// Read a type name including optional `[...]` generic arguments, so
/// `Map[K, V]::get` and `Map[A, B]::get` stay distinct identities.
fn type_name_with_generics(text : String) -> String {
  let base = first_identifier(text)
  if base.length() == 0 {
    return ""
  }
  let after_base = match text.split_once(base) {
    Some((_, rest)) => rest
    None => return base
  }
  if !after_base.has_prefix("[") {
    return base
  }
  let mut depth = 0
  let mut generics = ""
  for char in after_base {
    generics = generics + char.to_string()
    if char == '[' {
      depth = depth + 1
    } else if char == ']' {
      depth = depth - 1
      if depth == 0 {
        return base + generics
      }
    }
  }
  base + generics
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
  name_after(declaration_line(signature), keyword)
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
/// Read a multi-line block declaration starting at `start` until brace
/// depth returns to zero. Returns the joined block text and the index
/// of the first line after the block.
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
/// Rank visibility so tightening can be detected by comparison:
/// `pub(all)` = 3, `pub` = 2, package-private = 1.
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
