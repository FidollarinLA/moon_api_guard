// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "FidollarinLA/moon_api_guard"

version = "0.3.0"

readme = "README.md"

repository = "https://github.com/FidollarinLA/moon_api_guard"

license = "Apache-2.0"

keywords = [ "api-compatibility", "semver", "mbti", "ci", "moonbit" ]

preferred_target = "wasm-gc"

description = "Public API compatibility checks for MoonBit packages."

import {
  "moonbitlang/x@0.4.46",
}
