///|
test "parse check command" {
  let command = parse_command([
    "moon_api_guard", "check", "fixtures/old_api.mbti", "fixtures/new_api.mbti",
  ])
  inspect(command is Check(_, _), content="true")
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
test "run check reads identical fixture files" {
  run_check("fixtures/old_api.mbti", "fixtures/old_api.mbti")
}

///|
test "print usage is callable" {
  print_usage()
}

///|
test "print report renders summary" {
  let report = @lib.compare_api(
    @lib.parse_mbti_items(["pub fn parse(String) -> Int"]),
    @lib.parse_mbti_items(["pub fn parse(String) -> String"]),
  )
  print_report(report)
}
