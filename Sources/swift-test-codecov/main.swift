
import ArgumentParser
import Foundation
import SwiftTestCodecovLib

extension CodeCov.AggregateProperty: ExpressibleByArgument {}

let codecovFileDiscussion = """
You will find this in the build directory.

For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.
"""

/// How to display the results.
enum PrintFormat: String, CaseIterable, ExpressibleByArgument {
    case minimal
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

        let aggregateCoverage = Aggregate(
            coverage: codeCoverage,
            property: aggProperty,
            includeDependencies: includeDependencies,
            includeTests: includeTests,
            projectName: projectName
        )

        if aggregateCoverage.totalCount == 0 {
            print("")
            print("No coverage was analyzed.")
            print("Double check that you are either running this tool from the root of your target project or else you've specified a project-name that has the exact name of the root folder of your target project -- otherwise, all files may be filtered out as belonging to other projects (dependencies).")
            return
        }

        let passed = aggregateCoverage.overallCoveragePercent > Double(minimumCov)

        if !passed{
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
        case .json:
            printJson(aggregateCoverage)
        }
    }

    func printMinimal(_ aggregateCoverage: Aggregate) {
        print(aggregateCoverage.formattedOverallCoveragePercent)
    }

    func printJson(_ aggregateCoverage: Aggregate) {
        print(String(data: try! Self.jsonEncoder.encode(aggregateCoverage), encoding: .utf8)!)
    }
}

StatsCommand.main()
