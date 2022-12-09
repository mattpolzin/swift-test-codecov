
import ArgumentParser
import Foundation
import SwiftTestCodecovLib
import TextTable

extension CodeCov.AggregateProperty: ExpressibleByArgument {}

let codecovFileDiscussion = """
You will find this in the build directory.

For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.
"""

/// How to display the results.
enum PrintFormat: String, CaseIterable, ExpressibleByArgument {
    case minimal
    case numeric
    case table
    case json
}

/// How to sort the coverage table results (if `PrintFormat` is `.table`).
enum SortOrder: String, CaseIterable, ExpressibleByArgument {
    case filename
    case coverageAsc = "+cov"
    case coverageDesc = "-cov"
}

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
    var sort: SortOrder = .filename

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

        let data = try! Data(contentsOf: URL(fileURLWithPath: codecovFile))

        let codeCoverage = try! Self.jsonDecoder.decode(CodeCov.self, from: data)

        let aggregateCoverage: Aggregate
        do {
            aggregateCoverage = try Aggregate(
                coverage: codeCoverage,
                property: aggProperty,
                includeDependencies: includeDependencies,
                includeTests: includeTests,
                excludeRegexString: excludeRegexString,
                projectName: projectName
            )
        } catch {
            if printFormat == .json {
                print("{}")
            } else {
                print("Invalid `exclude-path` unable to parse '\(String(describing: excludeRegexString))' as regular expression.")
            }
            throw ExitCode.failure
        }

        if aggregateCoverage.totalCount == 0 && printFormat != .json && warnMissingTests {
            print("")
            print("No coverage was analyzed.")
            print("")
            print("Double check that you are either running this tool from the root of your target project or else you've specified a project-name that has the exact name of the root folder of your target project -- otherwise, all files may be filtered out as belonging to other projects (dependencies).")
        }

        let passed = aggregateCoverage.overallCoveragePercent > Double(minimumCov)

        if !passed && printFormat != .json && explainFailure {
            // we don't print the error message out for the minimal or JSON formats.
            print("")
            print("The overall coverage did not meet the minimum threshold of \(minimumCov)%")
        }

        printResults(aggregateCoverage)

        guard passed else {
            throw ExitCode.failure
        }
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
        print(aggregateCoverage.formattedOverallCoveragePercent)
    }
    
    func printNumeric(_ aggregateCoverage: Aggregate) {
        print(aggregateCoverage.overallCoveragePercent)
    }

    func printTable(_ aggregateCoverage: Aggregate) {
        
        print("")
        print("Overall Coverage: \(aggregateCoverage.formattedOverallCoveragePercent)")
        print("")

        typealias CoverageTriple = (dependency: Bool, filename: String, coverage: Double)

        let fileCoverages: [CoverageTriple] = aggregateCoverage.coveragePerFile.map {
            (
                dependency: isDependencyPath($0.key, projectName: projectName),
                filename: URL(fileURLWithPath: $0.key).lastPathComponent,
                coverage: $0.value.percent
            )
        }.sorted { $0.filename < $1.filename }

        let sortedCoverage : [CoverageTriple]
        switch sort {
        case .filename:
            // we always sort by filename above, even if we subsequently sort by another field.
            sortedCoverage = fileCoverages
        case .coverageAsc:
            sortedCoverage = fileCoverages.sorted { $0.coverage < $1.coverage }
        case .coverageDesc:
            sortedCoverage = fileCoverages.sorted { $0.coverage > $1.coverage }
        }

        var sourceCoverages = [CoverageTriple]()
        var testCoverages = [CoverageTriple]()
        for fileCoverage in sortedCoverage {
            if fileCoverage.filename.contains("Tests") {
                testCoverages.append(fileCoverage)
            } else {
                sourceCoverages.append(fileCoverage)
            }
        }
        let blankTriple: CoverageTriple = (false, "", -1)
        let dividerTriple: CoverageTriple = (false, "=-=-=-=-=-=-=-=-=", -1)

        let table = TextTable<CoverageTriple> {
            return [
                self.includeDependencies
                    ? Column(title: "Dependency?", value: $0.dependency ? "✓" : "", align: .center)
                    : nil,
                Column(title: "File", value: $0.filename),
                Column(title: "Coverage", value: $0.coverage >= 0 ? "\(String(format: "%.2f", $0.coverage))%" : ""),
            ].compactMap { $0 }
        }

        table.print(sourceCoverages + [blankTriple, dividerTriple, blankTriple] + testCoverages, style: Simple.self)
    }

    func printJson(_ aggregateCoverage: Aggregate) {
        print(String(data: try! Self.jsonEncoder.encode(aggregateCoverage), encoding: .utf8)!)
    }
}

StatsCommand.main()
