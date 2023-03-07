# swift-test-codecov

I'm writing this because tooling that can ingest the code coverage report produced by `swift test --enable-code-coverage` is shockingly hard to find.

## Usage

### Library

The library has a pretty small and straight forward interface. I have not had time to write about it here in the README, but taking a look at how the executable target uses the library target should be pretty informative.

### Tool

The tool is meant to be run from the root folder of your project. The executable can be anywhere but the current working directory is important for the tool to accurately identify which files are part of your project and which files are part of a dependency's project.

```
OVERVIEW: Analyze Code Coverage Metrics

Ingest Code Coverage Metrics provided by `swift test --enable-code-coverage` and provide some high level analysis.

USAGE: swift-test-codecov <options>

ARGUMENTS:
  <codecov-filepath>      The location of the JSON file output by `swift test --enable-code-coverage`. 
        You will find this in the build directory.

        For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.

OPTIONS:
  --project-name <project-name>
                          The name of the target project. 
        If specified, used to determine which source files being tested are outside of this project (local dependencies).
  -m, --metric <metric>   The metric over which to aggregate. One of lines, functions, instantiations (default: lines)
  -v, --minimum <minimum-coverage>
                          The minimum coverage percentage allowed. A value between 0 and 100. Coverage below the minimum will result in exit code 1. (default: 0.0)
  --fail-on-negative-delta/--no-fail-on-negative-delta
                          When enabled a coverage amount lower than the base will result in exit code 1. (default: false)
        Requires a previous run's JSON file is passed with option `--base-json-file` or will be treated as `false`.
  --explain-failure/--no-explain-failure
                          Determines whether a message will be displayed if the minimum coverage threshold was not met. (The `json` print-format will never display messages and will always be parsable
                          JSON.) (default: true)
  -p, --print-format <print-format>
                          Set the print format. One of minimal, numeric, table, json (default: minimal)
  -s, --sort <sort>       Set the sort order for the coverage table. One of filename, +cov, -cov (default: filename)
  --dependencies/--no-dependencies
                          Determines whether dependencies are included in code coverage calculation. (default: false)
  --tests/--no-tests      Determines whether test files are included in coverage calculation. (default: false)
  -x, --exclude-path <regex>
                          Regex pattern of full file paths to exclude in coverage calculation. 
        If specified, used to determine which source files being tested should be excluded. (Example value "View\.swift|Mock\.swift" excludes all files with names ending with `View` or `Mock`.)

        If the regular expression cannot be parsed by the system, the application will exit with code 1. An error message will be printed unless the `print-format` is set to `json`, in which case an
        empty object (`{}`) will be printed.
  -b, --base-json-file <previous-filepath>
                          The location of the JSON file output by a previous run of `swift-test-codecov` with the `-p json` print format. 
        If specified, the `minimal`, `table`, and `json` print formats will include total coverage, and if applicable, file-by-file differences. The `numeric` format will return the difference between
        the base file and the current run.
  --warn-missing-tests/--no-warn-missing-tests
                          Determines whether a warning will be displayed if no coverage data is available. (The `json` print-format will never display messages and will always be parsable JSON.)
                          (default: true)
  -h, --help              Show help information.
```

## Building Docker Image
Run `docker build -t swift-test-codecov .` to build the docker image.

## Installing with Make

Run `sudo make install` to install.

Run `sudo make uninstall` to uninstall.
