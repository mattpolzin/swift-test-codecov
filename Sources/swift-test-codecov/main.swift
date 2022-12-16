
import ArgumentParser
import Foundation
import SwiftTestCodecovLogic
import SwiftTestCodecovLib
import TextTable

extension CodeCov.AggregateProperty: ExpressibleByArgument {}

let codecovFileDiscussion = """
You will find this in the build directory.

For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.
"""

enum StatsCommandError: Error {
    case fileError(String)
}

/// How to display the results.
enum PrintFormat: String, CaseIterable, ExpressibleByArgument {
    case minimal
    case numeric
    case table
    case json
}

extension SwiftTestCodecovLogic.SortOrder: ExpressibleByArgument {}
typealias TableSortOrder = SwiftTestCodecovLogic.SortOrder

struct StatsCommand: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "swift-test-codecov",
        abstract: "Analyze Code Coverage Metrics",
        discussion: "Ingest Code Coverage Metrics provided by `swift test --enable-code-coverage` and provide some high level analysis."
    )

    static let jsonDecoder = JSONDecoder()
    static let jsonEncoder = JSONEncoder()

    @Argument(
        help: ArgumentHelp(
            "The location of the JSON file output by `swift test --enable-code-coverage`.",
            discussion: codecovFileDiscussion,
            valueName: "codecov-filepath"
        )
    )
    var codecovFile: String

    @Option(
        help: ArgumentHelp(
            "The name of the target project.",
            discussion: "If specified, used to determine which source files being tested are outside of this project (local dependencies).",
            valueName: "project-name"
        )
    )
    var projectName: String?

    @Option(
        name: [.long, .short],
        help: ArgumentHelp("The metric over which to aggregate. One of "
            + CodeCov.AggregateProperty.allCases.map { $0.rawValue }.joined(separator: ", "))
    )
    var metric: CodeCov.AggregateProperty = .lines

    @Option(
        name: [.customLong("minimum"), .customShort("v")],
        help: ArgumentHelp(
            "The minimum coverage allowed. A value between 0 and 100. Coverage below the minimum will result in exit code 1.",
            valueName: "minimum-coverage"
        )
    )
    var minimumCoverage: Int = 0
    
    @Flag(
        name: [.customLong("fail-on-negative-delta")],
        inversion: .prefixedNo,
        help: ArgumentHelp(
            "When enabled a coverage amount lower than the base will result in exit code 1.",
            discussion: "Requires a previous run's JSON file is passed with option `--base-json-file` or will be treated as `false`."
        )
    )
    var failOnNegativeDelta: Bool = false
    
    @Flag(
        name: [.customLong("explain-failure")],
        inversion: .prefixedNo,
        help: ArgumentHelp("Determines whether a message will be displayed if the minimum coverage threshold was not met. (The `json` print-format will never display messages and will always be parsable JSON.)")
    )
    var explainFailure: Bool = true

    @Option(
        name: [.long, .short],
        parsing: .unconditional,
        help: ArgumentHelp("Set the print format. One of "
                            + PrintFormat.allCases.map { $0.rawValue }.joined(separator: ", "))
    )
    var printFormat: PrintFormat = .minimal

    @Option(
        name: [.long, .short],
        parsing: .unconditional,
        help: ArgumentHelp("Set the sort order for the coverage table. One of "
                            + SortOrder.allCases.map { $0.rawValue }.joined(separator: ", "))
    )
    var sort: TableSortOrder = .filename

    @Flag(
        name: [.customLong("dependencies")],
        inversion: .prefixedNo,
        help: ArgumentHelp("Determines whether dependencies are included in code coverage calculation.")
    )
    var includeDependencies: Bool = false

    @Flag(
        name: [.customLong("tests")],
        inversion: .prefixedNo,
        help: ArgumentHelp("Determines whether test files are included in coverage calculation.")
    )
    var includeTests: Bool = false
    
    @Option(
        name: [.customLong("exclude-path"), .customShort("x")],
        help: ArgumentHelp(
            "Regex pattern of full file paths to exclude in coverage calculation.",
            discussion: "If specified, used to determine which source files being tested should be excluded. (Example value \"View\\.swift|Mock\\.swift\" excludes all files with names ending with `View` or `Mock`.)\n\nIf the regular expression cannot be parsed by the system, the application will exit with code 1. An error message will be printed unless the `print-format` is set to `json`, in which case an empty object (`{}`) will be printed.",
            valueName: "regex"
        )
    )
    var excludeRegexString: String?
    
    @Option(
        name: [.customLong("base-json-file"), .customShort("b")],
        help: ArgumentHelp(
            "The location of the JSON file output by a previous run of `swift-test-codecov` with the `-p json` print format.",
            discussion: "If specified, the `minimal`, `table`, and `json` print formats will include total coverage, and if applicable, file-by-file differences. The `numeric` format will return the difference between the base file and the current run.",
            valueName: "previous-filepath"
        )
    )
    var baseJSONFile: String?
    
    @Flag(
        name: [.customLong("warn-missing-tests")],
        inversion: .prefixedNo,
        help: ArgumentHelp("Determines whether a warning will be displayed if no coverage data is available. (The `json` print-format will never display messages and will always be parsable JSON.)")
    )
    var warnMissingTests: Bool = true
    
    func validate() throws {
        guard (0...100).contains(minimumCoverage) else {
            throw ValidationError("Minimum coverage must be between 0 and 100 because it represents a percentage.")
        }
    }

    func run() throws {

        let aggProperty: CodeCov.AggregateProperty = metric
        let minimumCov = minimumCoverage

        let codeCoverage: CodeCov
        var baseCoverage: Aggregate? = nil
        do {
            codeCoverage = try openJSON(file: codecovFile, parameterName: "codecov-filepath")
            if let baseJSONFile {
                baseCoverage = try openJSON(file: baseJSONFile, parameterName: "previous-filepath")
            }
        } catch StatsCommandError.fileError(let message) {
            print(message)
            throw ExitCode.failure
        } catch {
            print("An unexpected error occurred, please check your parameters and try again.")
            throw ExitCode.failure
        }

        let aggregateCoverage: Aggregate
        do {
            aggregateCoverage = try Aggregate(
                coverage: codeCoverage,
                property: aggProperty,
                includeDependencies: includeDependencies,
                includeTests: includeTests,
                excludeRegexString: excludeRegexString,
                projectName: projectName,
                fromBase: baseCoverage
            )
        } catch AggregateError.invalidBaseAggregate(let baseMetric) {
            print("The file specified at `previous-filepath` was run with metric `\(baseMetric)` which is different from `\(metric)`.")
            throw ExitCode.failure
        } catch {
            if printFormat == .json {
                print("{}")
            } else {
                print("Invalid `exclude-path`: unable to parse '\(String(describing: excludeRegexString))' as regular expression.")
            }
            throw ExitCode.failure
        }

        if aggregateCoverage.totalCount == 0 && printFormat != .json && warnMissingTests {
            print("")
            print("No coverage was analyzed.")
            print("")
            print("Double check that you are either running this tool from the root of your target project or else you've specified a project-name that has the exact name of the root folder of your target project -- otherwise, all files may be filtered out as belonging to other projects (dependencies).")
        }
        

        let passedMinimumCoverage = aggregateCoverage.overallCoveragePercent >= Double(minimumCov)

        if !passedMinimumCoverage && printFormat != .json && explainFailure {
            // we don't print the error message out for the minimal or JSON formats.
            print("")
            print("The overall coverage did not meet the minimum threshold of \(minimumCov)%")
        }
        
        let passedNonNegativeCoverageDelta = !failOnNegativeDelta || !aggregateCoverage.coverageDecreased
        
        if !passedNonNegativeCoverageDelta && explainFailure {
            // we don't print the error message out for the minimal or JSON formats.
            print("")
            let filePath: String
            if let baseJSONFile {
                filePath = " located at \(baseJSONFile)"
            } else {
                filePath = ""
            }
            print("The overall coverage has gone down relative to the base JSON file\(filePath)")
        }

        printResults(aggregateCoverage)

        guard passedMinimumCoverage && passedNonNegativeCoverageDelta else {
            throw ExitCode.failure
        }
    }
    
    func openJSON<T: Decodable>(file: String, parameterName: String) throws -> T {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: file))
        } catch {
            throw StatsCommandError.fileError("The `\(parameterName)` file `\(file)` could not be found or opened.")
        }

        let result: T
        do {
            result = try Self.jsonDecoder.decode(T.self, from: data)
        } catch {
            throw StatsCommandError.fileError("The file `\(file)` specified for `\(parameterName)` does not appear to be in the expected JSON format.")
        }
        
        return result
    }
}

extension StatsCommand {

    func printResults(_ aggregateCoverage: Aggregate) {
        switch printFormat {
        case .minimal:
            printMinimal(aggregateCoverage)
        case .numeric:
            printNumeric(aggregateCoverage)
        case .table:
            printTable(aggregateCoverage)
        case .json:
            printJson(aggregateCoverage)
        }
    }

    func printMinimal(_ aggregateCoverage: Aggregate) {
        print(aggregateCoverage.minimalDisplay)
    }
    
    func printNumeric(_ aggregateCoverage: Aggregate) {
        print(aggregateCoverage.numericDisplay)
    }

    func printTable(_ aggregateCoverage: Aggregate) {
        
        print("")
        print("Overall Coverage: \(aggregateCoverage.minimalDisplay)")
        print("")
        
        let tableData = aggregateCoverage.asTableData(
            includeDependencies: includeDependencies,
            projectName: projectName,
            sortOrder: sort
        )
        
        let table = TextTable<CoverageTableRow> { coverageTableRow in
            [
                Column(
                    title: "Dependency?",
                    value: coverageTableRow.isDependencyString,
                    align: .center
                )
                .includeIf(includeDependencies),
                
                Column(
                    title: "File",
                    value: coverageTableRow.filename
                ),
                
                Column(
                    title: "Coverage",
                    value: coverageTableRow.coverageString,
                    align: .right
                ),
                
                Column(
                    title: "Coverage Change",
                    value: coverageTableRow.coverageDeltaString,
                    align: .right
                )
                .includeIf(aggregateCoverage.hasDeltas),
                
            ].compactMap { $0 }
        }

        table.print(tableData.splitOutTests(), style: Simple.self)
    }

    func printJson(_ aggregateCoverage: Aggregate) {
        print(String(data: try! Self.jsonEncoder.encode(aggregateCoverage), encoding: .utf8)!)
    }
}

StatsCommand.main()
