
import ArgumentParser
import Foundation
import SwiftTestCodecovLib
import TextTable

extension CodeCov.AggregateProperty: ExpressibleByArgument {}

let codecovFileDiscussion = """
You will find this in the build directory.

For example, if you've just performed a debug build, the file will be located at `./.build/debug/codecov/<package-name>.json`.
"""

struct StatsCommand: ParsableCommand {
    static let configuration: CommandConfiguration = .init(
        commandName: "swift-test-codecov",
        abstract: "Analyze Code Coverage Metrics",
        discussion: "Ingest Code Coverage Metrics provided by `swift test --enable-code-coverage` and provide some high level analysis."
    )

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

    @Flag(
        name: [.customLong("table"), .customShort("t")],
        help: ArgumentHelp("Prints an ascii table of coverage numbers.")
    )
    var printTable: Bool = false

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
        let jsonDecoder = JSONDecoder()

        let aggProperty: CodeCov.AggregateProperty = metric
        let minimumCov = minimumCoverage

        let data = try! Data(contentsOf: URL(fileURLWithPath: codecovFile))

        let codeCoverage = try! jsonDecoder.decode(CodeCov.self, from: data)

        func isDependencyPath(_ path: String) -> Bool {
            return path.contains(".build/")
        }

        let coveragePerFile = codeCoverage
            .fileCoverages(for: aggProperty)
            .filter { filename, _ in
                includeDependencies ? true : !isDependencyPath(filename)
            }

        let totalCountOfProperty = coveragePerFile.reduce(0) { tot, next in
            tot + next.value.count
        }

        let overallCoverage = coveragePerFile.reduce(0.0) { avg, next in
            avg + Double(next.value.covered) / Double(totalCountOfProperty)
        }

        let overallCoveragePercent = overallCoverage * 100

        let formattedOverallPercent = "\(String(format: "%.2f", overallCoveragePercent))%"

        guard overallCoveragePercent > Double(minimumCov) else {
            print("The overall coverage (\(formattedOverallPercent)) did not meet the minimum threshold of \(minimumCov)%")
            throw ExitCode.failure
        }

        guard printTable else {
            print(formattedOverallPercent)
            return
        }

        print("Overall Coverage: \(formattedOverallPercent)")
        print("")

        typealias CoverageTriple = (dependency: Bool, filename: String, coverage: Double)

        let fileCoverages: [CoverageTriple] = coveragePerFile.map {
            (
                dependency: isDependencyPath($0.key),
                filename: URL(fileURLWithPath: $0.key).lastPathComponent,
                coverage: $0.value.percent
            )
        }.sorted { $0.filename < $1.filename }

        var sourceCoverages = [CoverageTriple]()
        var testCoverages = [CoverageTriple]()
        for fileCoverage in fileCoverages {
            if fileCoverage.filename.contains("Tests") {
                testCoverages.append(fileCoverage)
            } else {
                sourceCoverages.append(fileCoverage)
            }
        }
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

        table.print(sourceCoverages + [dividerTriple] + testCoverages, style: Simple.self)
    }
}

StatsCommand.main()
