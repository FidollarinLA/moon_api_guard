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
