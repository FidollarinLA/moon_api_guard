///|
/// CLI entry point for moon_api_guard.
fn main {
  let args = @sys.get_cli_args()
  match parse_command(args) {
    Check(old_path, new_path) => run_check(old_path, new_path)
    Help => print_usage()
    Invalid(message) => {
      println("error: \{message}")
      print_usage()
      @sys.exit(2)
    }
  }
}

///|
enum Command {
  Check(String, String)
  Help
  Invalid(String)
}

///|
fn parse_command(args : Array[String]) -> Command {
  if args.length() <= 1 {
    Help
  } else if args[1] == "check" {
    if args.length() < 4 {
      Invalid("check requires two .mbti file paths")
    } else {
      Check(args[2], args[3])
    }
  } else if args[1] == "help" || args[1] == "--help" || args[1] == "-h" {
    Help
  } else {
    Invalid("unknown command: \{args[1]}")
  }
}

///|
fn run_check(old_path : String, new_path : String) -> Unit {
  let old_content = read_mbti_file(old_path)
  let new_content = read_mbti_file(new_path)
  let old_items = @lib.parse_mbti_content(old_content)
  let new_items = @lib.parse_mbti_content(new_content)
  let report = @lib.compare_api(old_items, new_items)
  print_report(report)
  if report.release_blocked() {
    @sys.exit(1)
  }
}

///|
fn read_mbti_file(path : String) -> String {
  @fs.read_file_to_string(path) catch {
    IOError(message) => fail_read(path, message)
  }
}

///|
fn fail_read(path : String, message : String) -> String {
  println("error: failed to read \{path}: \{message}")
  @sys.exit(2)
  ""
}

///|
fn print_report(report : @lib.ApiReport) -> Unit {
  println("moon_api_guard report")
  println("breaking: \{report.breaking_count()}")
  println("compatible: \{report.compatible_count()}")
  println("semver: \{report.semver_suggestion()}")
  println("release_blocked: \{report.release_blocked()}")
  println(report.markdown_summary())
  println(report.json_summary())
}

///|
fn print_usage() -> Unit {
  println("moon_api_guard - MoonBit public API compatibility guard")
  println("")
  println("Usage:")
  println("  moon run cmd/main -- check <old.mbti> <new.mbti>")
  println("  moon run cmd/main -- help")
  println("")
  println("Exit codes:")
  println("  0 - no breaking changes")
  println("  1 - breaking changes detected")
  println("  2 - invalid usage or file read error")
}
