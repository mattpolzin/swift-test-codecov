# swift-test-codecov

At the moment this script just prints out one percentage: The total code coverage by line of the first set of files found in the codecov report.

I'm writing this because tooling that can ingest the code coverage report produced by `swift test --enable-code-coverage` is shockingly hard to find.

## Usage

```
swift-test-codecov <path-to-codecov-json> [options]

Options:
  -d, --dependencies       Include dependencies in code coverage calculation. False by default.
  -h, --help               Show help information
  -m, --metric <value>     The metric over which to aggregate. Options are [lines, functions, instantiations]
  -t, --table              Prints an ascii table of coverage numbers.
  -v, --minimum <value>    The minimum coverage allowed. If set, coverage below the minimum will result in exit code 1.
```

`<path-to-codecov-json>` is the location of the JSON file output by `swift test --enable-code-coverage`. You will find this in the build directory.

For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.
