///|
/// Severity override for one classification `detail` key.
///
/// - `category` is `"breaking"`, `"compatible"`, or `"ignore"`.
/// - `"ignore"` drops matching findings from the report entirely.
pub(all) struct RuleOverride {
  detail : String
  category : String
} derive(Eq, Debug)

///|
/// Compatibility policy applied after structural classification.
///
/// Use `default_compat_policy()` for MoonBit-oriented defaults, or
/// `strict_compat_policy()` to treat nearly all signature diffs as
/// breaking unless overridden.
pub(all) struct CompatPolicy {
  overrides : Array[RuleOverride]
} derive(Debug)

///|
/// MoonBit-oriented defaults: adding labeled optional parameters is
/// compatible; enum variant additions remain breaking.
pub fn default_compat_policy() -> CompatPolicy {
  {
    overrides: [
      { detail: "optional-parameter-added", category: "compatible" },
      { detail: "raise-removed", category: "compatible" },
    ],
  }
}

///|
/// Strict policy with no built-in remaps. Attribute-only deprecations
/// remain compatible because they are classified before policy remaps.
pub fn strict_compat_policy() -> CompatPolicy {
  { overrides: [] }
}

///|
/// Remap one detail key to `"compatible"`.
pub fn policy_allow(policy : CompatPolicy, detail : String) -> CompatPolicy {
  policy_with_override(policy, detail, "compatible")
}

///|
/// Drop findings with the given detail key from reports.
pub fn policy_ignore(policy : CompatPolicy, detail : String) -> CompatPolicy {
  policy_with_override(policy, detail, "ignore")
}

///|
/// Insert or replace an override for `detail`.
pub fn policy_with_override(
  policy : CompatPolicy,
  detail : String,
  category : String,
) -> CompatPolicy {
  let overrides : Array[RuleOverride] = []
  let mut replaced = false
  for item in policy.overrides {
    if item.detail == detail {
      overrides.push({ detail, category })
      replaced = true
    } else {
      overrides.push(item)
    }
  }
  if !replaced {
    overrides.push({ detail, category })
  }
  { overrides, }
}

///|
fn CompatPolicy::category_for(
  self : CompatPolicy,
  detail : String,
  fallback : String,
) -> String {
  for item in self.overrides {
    if item.detail == detail {
      return item.category
    }
  }
  fallback
}

///|
/// Build a `CompatPolicy` from a JSON policy document.
///
/// Expected shape:
/// ```text
/// {
///   "strict": false,
///   "allow": ["variant-added"],
///   "ignore": ["deprecated"]
/// }
/// ```
///
/// Missing fields default to `strict=false` and empty allow/ignore lists.
/// Returns `None` when the text is not valid policy JSON.
pub fn policy_from_json_text(text : String) -> CompatPolicy? {
  let json = @json.parse(text) catch { _ => return None }
  guard json is Object(obj) else { return None }
  let strict = match obj.get("strict") {
    None => false
    Some(True) => true
    Some(False) => false
    _ => return None
  }
  let allow = match json_string_array(obj.get("allow")) {
    Some(items) => items
    None => return None
  }
  let ignore = match json_string_array(obj.get("ignore")) {
    Some(items) => items
    None => return None
  }
  let mut policy = if strict {
    strict_compat_policy()
  } else {
    default_compat_policy()
  }
  for detail in allow {
    policy = policy_allow(policy, detail)
  }
  for detail in ignore {
    policy = policy_ignore(policy, detail)
  }
  Some(policy)
}

///|
fn json_string_array(value : Json?) -> Array[String]? {
  match value {
    None => Some([])
    Some(Array(items)) => {
      let out : Array[String] = []
      for item in items {
        guard item is String(s) else { return None }
        out.push(s)
      }
      Some(out)
    }
    _ => None
  }
}
