///|
test "parse check command" {
  let command = parse_command([
    "moon_api_guard", "check", "fixtures/old_api.mbti", "fixtures/new_api.mbti",
  ])
  inspect(command is Check(_, _, _, _), content="true")
}

///|
test "parse check command with json format and breaking only" {
  let command = parse_command([
    "moon_api_guard", "check", "fixtures/old_api.mbti", "fixtures/new_api.mbti",
    "--format", "json", "--breaking-only",
  ])
  match command {
    Check(_, _, format, breaking_only) => {
      inspect(format, content="json")
      inspect(breaking_only, content="true")
    }
    _ => inspect(false, content="true")
  }
}

///|
test "parse check-dir command" {
  let command = parse_command([
    "moon_api_guard", "check-dir", "fixtures/dir_old", "fixtures/dir_new",
  ])
  inspect(command is CheckDir(_, _, _, _), content="true")
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
  run_check("fixtures/old_api.mbti", "fixtures/old_api.mbti", "text", false)
}

///|
test "run check-dir fixtures produce expected signals" {
  let report = compare_mbti_dirs("fixtures/dir_old", "fixtures/dir_new")
  inspect(report.breaking_count() > 0, content="true")
  inspect(report.compatible_count() > 0, content="true")
  inspect(report.release_blocked(), content="true")
  let breaking = report.breaking_only()
  inspect(breaking.compatible_count(), content="0")
  inspect(breaking.breaking_count() > 0, content="true")
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
