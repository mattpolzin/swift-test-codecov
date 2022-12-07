# swift-test-codecov

I'm writing this because tooling that can ingest the code coverage report produced by `swift test --enable-code-coverage` is shockingly hard to find.

## Usage

### Library

The library has a pretty small and straight forward interface. I have not had time to write about it here in the README, but taking a look at how the executable target uses the library target should be pretty informative.

### Tool

The tool is meant to be run from the root folder of your project. The executable can be anywhere but the current working directory is important for the tool to accurately identify which files are part of your project and which files are part of a dependency's project.

```
USAGE: swift-test-codecov <codecov-filepath> [--metric <metric>] [--minimum <minimum-coverage>] [--print-format <print-format>] [--sort <sort>] [--dependencies] [--no-dependencies] [--tests] [--no-tests]

ARGUMENTS:
  <codecov-filepath>      the location of the JSON file output by `swift test --enable-code-coverage`. 
        You will find this in the build directory.

        For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.

OPTIONS:
  -m, --metric <metric>   The metric over which to aggregate. One of lines, functions, instantiations (default: lines)
  -v, --minimum <minimum-coverage>
                          The minimum coverage allowed. A value between 0 and 100. Coverage below the minimum will result in
                          exit code 1. (default: 0)
  -p, --print-format <print-format>
                          Set the print format. One of minimal, table, json (default: minimal)
  -s, --sort <sort>       Set the sort order for the coverage table. One of filename, +cov, -cov (default: filename)
  --dependencies/--no-dependencies
                          Determines whether dependencies are included in code coverage calculation. (default: false)
  --tests/--no-tests      Determines whether test files are included in coverage calculation. (default: false)
  -h, --help              Show help information.
```

## Building Docker Image
Run `docker build -t swift-test-codecov .` to build the docker image.

## Installing with Make

Run `sudo make install` to install on MacOS.

Run `sudo make uninstall` to uninstall.
