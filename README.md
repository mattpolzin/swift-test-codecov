# swift-test-codecov

I'm writing this because tooling that can ingest the code coverage report produced by `swift test --enable-code-coverage` is shockingly hard to find.

## Usage

### Library

The library has a pretty small and straight forward interface. I have not had time to write about it here in the README, but taking a look at how the executable target uses the library target should be pretty informative.

### Tool

```
swift-test-codecov <codecov-filepath> [--metric <metric>] [--minimum <minimum-coverage>] [--table] [--dependencies]

ARGUMENTS:
  <codecov-filepath>      the location of the JSON file output by `swift test --enable-code-coverage`. 
        You will find this in the build directory.

        For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.

OPTIONS:
  -m, --metric <metric>   The metric over which to aggregate. One of ["lines", "functions", "instantiations"] (default: lines)
  -v, --minimum <minimum-coverage>
                          The minimum coverage allowed. A value between 0 and 100. Coverage below the minimum will result in exit code 1. (default: 0)
  -t, --table             Prints an ascii table of coverage numbers. 
  -d, --dependencies      Include dependencies in code coverage calculation. 
  -h, --help              Show help information.
```

## Building Docker Image
Run `docker build -t swift-test-codecov .` to build the docker image.
