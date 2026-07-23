///|
/// CLI entry point for moon_api_guard.
fn main {
  let args = @sys.get_cli_args()
  match parse_command(args) {
    Check(old_path, new_path, opts) => run_check(old_path, new_path, opts)
    CheckDir(old_dir, new_dir, opts) => run_check_dir(old_dir, new_dir, opts)
    BaselineUpdate(current_path, baseline_path) =>
      run_baseline_update(current_path, baseline_path)
    Help => print_usage()
    Invalid(message) => {
      println("error: \{message}")
      print_usage()
      @sys.exit(2)
    }
  }
}

///|
priv struct CheckOpts {
  format : String
  breaking_only : Bool
  policy : @lib.CompatPolicy
}

///|
enum Command {
  Check(String, String, CheckOpts)
  CheckDir(String, String, CheckOpts)
  BaselineUpdate(String, String)
  Help
  Invalid(String)
}

///|
fn parse_command(args : Array[String]) -> Command {
  if args.length() <= 1 {
    return Help
  }
  let cmd = args[1]
  if cmd == "help" || cmd == "--help" || cmd == "-h" {
    return Help
  }
  if cmd == "baseline" {
    return parse_baseline_command(args)
  }
  if cmd == "check" || cmd == "check-dir" {
    return parse_check_like_command(args, cmd)
  }
  Invalid("unknown command: \{cmd}")
}

///|
fn parse_baseline_command(args : Array[String]) -> Command {
  if args.length() < 3 || args[2] != "update" {
    return Invalid("baseline requires subcommand: update")
  }
  if args.length() < 5 {
    return Invalid("baseline update requires <current.mbti> <baseline.mbti>")
  }
  if args.length() > 5 {
    return Invalid("unexpected argument: \{args[5]}")
  }
  BaselineUpdate(args[3], args[4])
}

///|
fn parse_check_like_command(args : Array[String], cmd : String) -> Command {
  let mut left = ""
  let mut right = ""
  let mut format = "text"
  let mut breaking_only = false
  let mut strict = false
  let mut allow = ""
  let mut ignore = ""
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
    } else if arg == "--breaking-only" {
      breaking_only = true
      index = index + 1
    } else if arg == "--strict" {
      strict = true
      index = index + 1
    } else if arg == "--allow" {
      if index + 1 >= args.length() {
        return Invalid("--allow requires a comma-separated detail list")
      }
      allow = args[index + 1]
      index = index + 2
    } else if arg == "--ignore" {
      if index + 1 >= args.length() {
        return Invalid("--ignore requires a comma-separated detail list")
      }
      ignore = args[index + 1]
      index = index + 2
    } else if left.length() == 0 {
      left = arg
      index = index + 1
    } else if right.length() == 0 {
      right = arg
      index = index + 1
    } else {
      return Invalid("unexpected argument: \{arg}")
    }
  }
  let opts : CheckOpts = {
    format,
    breaking_only,
    policy: build_policy(strict, allow, ignore),
  }
  if left.length() == 0 || right.length() == 0 {
    if cmd == "check-dir" {
      Invalid("check-dir requires two directory paths")
    } else {
      Invalid("check requires two .mbti file paths")
    }
  } else if cmd == "check-dir" {
    CheckDir(left, right, opts)
  } else {
    Check(left, right, opts)
  }
}

///|
fn build_policy(
  strict : Bool,
  allow : String,
  ignore : String,
) -> @lib.CompatPolicy {
  let mut policy = if strict {
    @lib.strict_compat_policy()
  } else {
    @lib.default_compat_policy()
  }
  for detail in split_csv(allow) {
    policy = @lib.policy_allow(policy, detail)
  }
  for detail in split_csv(ignore) {
    policy = @lib.policy_ignore(policy, detail)
  }
  policy
}

///|
fn split_csv(text : String) -> Array[String] {
  let parts : Array[String] = []
  if text.length() == 0 {
    return parts
  }
  for part in text.split(",") {
    let trimmed = part.trim(char_set=" \t\r").to_owned()
    if trimmed.length() > 0 {
      parts.push(trimmed)
    }
  }
  parts
}

///|
fn run_check(old_path : String, new_path : String, opts : CheckOpts) -> Unit {
  let report = maybe_breaking_only(
    @lib.compare_mbti_content_with_policy(
      read_mbti_file(old_path),
      read_mbti_file(new_path),
      opts.policy,
    ),
    opts.breaking_only,
  )
  emit_report(report, opts.format)
}

///|
fn run_check_dir(old_dir : String, new_dir : String, opts : CheckOpts) -> Unit {
  let report = maybe_breaking_only(
    compare_mbti_dirs_with_policy(old_dir, new_dir, opts.policy),
    opts.breaking_only,
  )
  emit_report(report, opts.format)
}

///|
fn compare_mbti_dirs_with_policy(
  old_dir : String,
  new_dir : String,
  policy : @lib.CompatPolicy,
) -> @lib.ApiReport {
  let old_files = list_mbti_files(old_dir)
  let new_files = list_mbti_files(new_dir)
  let reports : Array[@lib.ApiReport] = []
  for path in old_files {
    if contains_string(new_files, path) {
      let report = @lib.compare_mbti_content_with_policy(
        read_mbti_file(join_path(old_dir, path)),
        read_mbti_file(join_path(new_dir, path)),
        policy,
      )
      reports.push(report.scoped(path))
    } else {
      reports.push(@lib.file_removed_report(path))
    }
  }
  for path in new_files {
    if !contains_string(old_files, path) {
      reports.push(@lib.file_added_report(path))
    }
  }
  @lib.merge_api_reports(reports)
}

///|
fn run_baseline_update(current_path : String, baseline_path : String) -> Unit {
  let content = read_mbti_file(current_path)
  @fs.write_string_to_file(baseline_path, content) catch {
    IOError(message) => {
      println("error: failed to write \{baseline_path}: \{message}")
      @sys.exit(2)
    }
  }
  println("baseline updated: \{baseline_path}")
}

///|
fn emit_report(report : @lib.ApiReport, format : String) -> Unit {
  print_report(report, format)
  if report.release_blocked() {
    @sys.exit(1)
  }
}

///|
fn maybe_breaking_only(
  report : @lib.ApiReport,
  breaking_only : Bool,
) -> @lib.ApiReport {
  if breaking_only {
    report.breaking_only()
  } else {
    report
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
fn list_mbti_files(root : String) -> Array[String] {
  let files : Array[String] = []
  collect_mbti_files(root, "", files)
  sort_strings(files)
  files
}

///|
fn collect_mbti_files(
  root : String,
  relative : String,
  files : Array[String],
) -> Unit {
  let path = if relative.length() == 0 {
    root
  } else {
    join_path(root, relative)
  }
  let entries = @fs.read_dir(path) catch {
    IOError(message) => {
      println("error: failed to read directory \{path}: \{message}")
      @sys.exit(2)
      []
    }
  }
  for entry in entries {
    if entry == "." || entry == ".." {
      continue
    }
    let child_rel = if relative.length() == 0 {
      entry
    } else {
      join_path(relative, entry)
    }
    let child_path = join_path(root, child_rel)
    let is_directory = @fs.is_dir(child_path) catch {
      IOError(message) => {
        println("error: failed to inspect \{child_path}: \{message}")
        @sys.exit(2)
        false
      }
    }
    if is_directory {
      collect_mbti_files(root, child_rel, files)
    } else if entry.has_suffix(".mbti") {
      files.push(child_rel)
    }
  }
}

///|
fn join_path(left : String, right : String) -> String {
  if left.has_suffix("/") {
    left + right
  } else {
    "\{left}/\{right}"
  }
}

///|
fn contains_string(items : Array[String], target : String) -> Bool {
  for item in items {
    if item == target {
      return true
    }
  }
  false
}

///|
fn sort_strings(items : Array[String]) -> Unit {
  let mut i = 0
  while i < items.length() {
    let mut j = i + 1
    while j < items.length() {
      if items[j] < items[i] {
        let tmp = items[i]
        items[i] = items[j]
        items[j] = tmp
      }
      j = j + 1
    }
    i = i + 1
  }
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
  println("  moon run cmd/main -- check <old.mbti> <new.mbti> [options]")
  println("  moon run cmd/main -- check-dir <old_dir> <new_dir> [options]")
  println(
    "  moon run cmd/main -- baseline update <current.mbti> <baseline.mbti>",
  )
  println("  moon run cmd/main -- help")
  println("")
  println("Options:")
  println("  --format text|markdown|json")
  println("  --breaking-only")
  println("  --strict")
  println("  --allow <detail>[,detail...]")
  println("  --ignore <detail>[,detail...]")
  println("")
  println("Exit codes:")
  println("  0 - no breaking changes")
  println("  1 - breaking changes detected")
  println("  2 - invalid usage or file read error")
}
