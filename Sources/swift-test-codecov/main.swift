
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
            "the location of the JSON file output by `swift test --enable-code-coverage`.",
            discussion: codecovFileDiscussion,
            valueName: "codecov-filepath"
        )
    )
    var codecovFile: String

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
        name: [.customLong("dependencies"), .customShort("d")],
        help: ArgumentHelp("Include dependencies in code coverage calculation.")
    )
    var includeDependencies: Bool = false

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
            includeDependencies: includeDependencies
        )

        let passed = aggregateCoverage.overallCoveragePercent > Double(minimumCov)

        if !passed && printFormat == .table {
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
        case .table:
            printTable(aggregateCoverage)
        case .json:
            printJson(aggregateCoverage)
        }
    }

    func printMinimal(_ aggregateCoverage: Aggregate) {
        print(aggregateCoverage.formattedOverallCoveragePercent)
    }

    func printTable(_ aggregateCoverage: Aggregate) {

        print("")
        print("Overall Coverage: \(aggregateCoverage.formattedOverallCoveragePercent)")
        print("")

        typealias CoverageTriple = (dependency: Bool, filename: String, coverage: Double)

        let fileCoverages: [CoverageTriple] = aggregateCoverage.coveragePerFile.map {
            (
                dependency: isDependencyPath($0.key),
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
