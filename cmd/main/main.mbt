///|
/// CLI entry point for moon_api_guard.
fn main {
  let args = @sys.get_cli_args()
  match parse_command(args) {
    Check(old_path, new_path, format) => run_check(old_path, new_path, format)
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
  Check(String, String, String)
  Help
  Invalid(String)
}

///|
fn parse_command(args : Array[String]) -> Command {
  if args.length() <= 1 {
    return Help
  }
  if args[1] == "help" || args[1] == "--help" || args[1] == "-h" {
    return Help
  }
  if args[1] != "check" {
    return Invalid("unknown command: \{args[1]}")
  }
  let mut old_path = ""
  let mut new_path = ""
  let mut format = "text"
  let mut index = 2
  while index < args.length() {
    let arg = args[index]
    if arg == "--format" {
      if index + 1 >= args.length() {
        return Invalid("--format requires text, markdown, or json")
      }
      format = args[index + 1]
      if format != "text" && format != "markdown" && format != "json" {
        return Invalid("unsupported format: \{format}")
      }
      index = index + 2
    } else if old_path.length() == 0 {
      old_path = arg
      index = index + 1
    } else if new_path.length() == 0 {
      new_path = arg
      index = index + 1
    } else {
      return Invalid("unexpected argument: \{arg}")
    }
  }
  if old_path.length() == 0 || new_path.length() == 0 {
    Invalid("check requires two .mbti file paths")
  } else {
    Check(old_path, new_path, format)
  }
}

///|
fn run_check(old_path : String, new_path : String, format : String) -> Unit {
  let old_content = read_mbti_file(old_path)
  let new_content = read_mbti_file(new_path)
  let report = @lib.compare_mbti_content(old_content, new_content)
  print_report(report, format)
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
fn print_report(report : @lib.ApiReport, format : String) -> Unit {
  if format == "json" {
    println(report.json_summary())
  } else if format == "markdown" {
    println(report.markdown_summary())
  } else {
    println("moon_api_guard report")
    println("breaking: \{report.breaking_count()}")
    println("compatible: \{report.compatible_count()}")
    println("semver: \{report.semver_suggestion()}")
    println("release_blocked: \{report.release_blocked()}")
    println(report.markdown_summary())
    println(report.json_summary())
  }
}

///|
fn print_usage() -> Unit {
  println("moon_api_guard - MoonBit public API compatibility guard")
  println("")
  println("Usage:")
  println(
    "  moon run cmd/main -- check <old.mbti> <new.mbti> [--format text|markdown|json]",
  )
  println("  moon run cmd/main -- help")
  println("")
  println("Exit codes:")
  println("  0 - no breaking changes")
  println("  1 - breaking changes detected")
  println("  2 - invalid usage or file read error")
}
