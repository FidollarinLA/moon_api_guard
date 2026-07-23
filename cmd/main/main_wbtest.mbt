///|
test "parse check command" {
  let command = parse_command([
    "moon_api_guard", "check", "fixtures/old_api.mbti", "fixtures/new_api.mbti",
  ])
  inspect(command is Check(_, _, _), content="true")
}

///|
test "parse check command with policy flags" {
  let command = parse_command([
    "moon_api_guard", "check", "fixtures/old_api.mbti", "fixtures/new_api.mbti",
    "--format", "json", "--breaking-only", "--strict", "--allow", "enum-variant-added",
    "--ignore", "deprecated", "--policy", "fixtures/policies/default-plus-variant.json",
  ])
  match command {
    Check(_, _, opts) => {
      inspect(opts.format, content="json")
      inspect(opts.breaking_only, content="true")
      inspect(opts.strict, content="true")
      inspect(opts.allow, content="enum-variant-added")
      inspect(opts.ignore, content="deprecated")
      inspect(
        opts.policy_path,
        content="fixtures/policies/default-plus-variant.json",
      )
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse check-dir command" {
  let command = parse_command([
    "moon_api_guard", "check-dir", "fixtures/dir_old", "fixtures/dir_new",
  ])
  inspect(command is CheckDir(_, _, _), content="true")
}

///|
test "parse baseline update command" {
  let command = parse_command([
    "moon_api_guard", "baseline", "update", "pkg.generated.mbti", "baseline/pkg.generated.mbti",
  ])
  inspect(command is BaselineUpdate(_, _), content="true")
}

///|
test "parse help command" {
  let command = parse_command(["moon_api_guard", "help"])
  inspect(command is Help, content="true")
}

///|
test "parse missing args falls back to help" {
  let command = parse_command(["moon_api_guard"])
  inspect(command is Help, content="true")
}

///|
test "parse check command with missing paths is invalid" {
  let command = parse_command(["moon_api_guard", "check", "only-one.mbti"])
  inspect(command is Invalid(_), content="true")
}

///|
test "parse unsupported format is invalid" {
  let command = parse_command([
    "moon_api_guard", "check", "a.mbti", "b.mbti", "--format", "yaml",
  ])
  inspect(command is Invalid(_), content="true")
}

///|
test "run check reads identical fixture files" {
  run_check("fixtures/old_api.mbti", "fixtures/old_api.mbti", {
    format: "text",
    breaking_only: false,
    strict: false,
    allow: "",
    ignore: "",
    policy_path: "",
  })
}

///|
test "run check-dir fixtures produce expected signals" {
  let report = compare_mbti_dirs_with_policy(
    "fixtures/dir_old",
    "fixtures/dir_new",
    @lib.default_compat_policy(),
  )
  inspect(report.breaking_count() > 0, content="true")
  inspect(report.compatible_count() > 0, content="true")
  inspect(report.release_blocked(), content="true")
  let breaking = report.breaking_only()
  inspect(breaking.compatible_count(), content="0")
  inspect(breaking.breaking_count() > 0, content="true")
}

///|
test "regression fs fixture treats optional params as compatible" {
  let report = @lib.compare_mbti_content(
    read_mbti_file("fixtures/regression/fs_old.mbti"),
    read_mbti_file("fixtures/regression/fs_new.mbti"),
  )
  inspect(report.release_blocked(), content="false")
  inspect(report.semver_suggestion(), content="minor")
  inspect(report.compatible_count() >= 2, content="true")
}

///|
test "regression raise fixture blocks on raise-type-changed" {
  let report = @lib.compare_mbti_content(
    read_mbti_file("fixtures/regression/raise_old.mbti"),
    read_mbti_file("fixtures/regression/raise_new.mbti"),
  )
  inspect(report.release_blocked(), content="true")
  inspect(report.breaking_count() >= 1, content="true")
}

///|
test "resolve policy loads JSON file and stacks CLI allow" {
  let policy = resolve_policy({
    format: "text",
    breaking_only: false,
    strict: false,
    allow: "raise-type-changed",
    ignore: "",
    policy_path: "fixtures/policies/default-plus-variant.json",
  })
  inspect(policy.overrides.length() >= 1, content="true")
  let report = @lib.compare_mbti_content_with_policy(
    "pub(all) enum Status {\n  Ok\n}", "pub(all) enum Status {\n  Ok\n  Warning\n}",
    policy,
  )
  inspect(report.breaking_count(), content="0")
  inspect(report.compatible_count(), content="1")
}

///|
test "print usage is callable" {
  print_usage()
}

///|
test "print report renders summary formats" {
  let report = @lib.compare_api(
    @lib.parse_mbti_items(["pub fn parse(String) -> Int"]),
    @lib.parse_mbti_items(["pub fn parse(String) -> String"]),
  )
  print_report(report, "text")
  print_report(report, "markdown")
  print_report(report, "json")
}

///|
test "list mbti files finds nested fixture" {
  let files = list_mbti_files("fixtures/dir_old")
  inspect(contains_string(files, "pkg.mbti"), content="true")
  inspect(contains_string(files, "nested/extra.mbti"), content="true")
}
