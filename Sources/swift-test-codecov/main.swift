
import Foundation
import SwiftTestCodecovLib
import SwiftCLI
import TextTable

extension CodeCov.AggregateProperty: ConvertibleFromString {}

class StatsCommand: Command {
    let name = "stats"
    let codecovFile = Parameter()
    let metric = Key<CodeCov.AggregateProperty>("-m",
                                                "--metric",
                                                description: "The metric over which to aggregate. Options are \(CodeCov.AggregateProperty.allCases)")
    let printTable = Flag("-t", "--table",
                     description: "Prints an ascii table of coverage numbers.",
                     defaultValue: false)

    let includeDependencies = Flag("-d", "--dependencies",
                            description: "Include dependencies in code coverage calculation. False by default.",
                            defaultValue: false)
    func execute() throws {
        let jsonDecoder = JSONDecoder()

        let aggProperty: CodeCov.AggregateProperty = metric.value ?? .lines

        let data = try! Data(contentsOf: URL(fileURLWithPath: codecovFile.value))

        let codeCoverage = try! jsonDecoder.decode(CodeCov.self, from: data)

        func isDependencyPath(_ path: String) -> Bool {
            return path.contains(".build/")
        }

        let coveragePerFile = codeCoverage
            .fileCoverages(for: aggProperty)
            .filter { filename, _ in
                includeDependencies.value ? true : !isDependencyPath(filename)
        }

        let totalCountOfProperty = coveragePerFile.reduce(0, {tot, next in
            tot + next.value.count
        })

        let overallCoverage = coveragePerFile.reduce(0.0, { avg, next in
            avg + Double(next.value.covered) / Double(totalCountOfProperty)
        })

        let overallCoveragePercent = overallCoverage * 100

        guard printTable.value else {
            print("\(String(format: "%.2f", overallCoveragePercent))%")
            return
        }

        print("Overall Coverage: \(String(format: "%.2f", overallCoveragePercent))%")
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

        let table = TextTable<CoverageTriple> {
            return [
                self.includeDependencies.value
                    ? Column(title: "Dependency?", value: $0.dependency ? "✓" : "", align: .center)
                    : nil,
                Column(title: "File", value: $0.filename),
                Column(title: "Coverage", value: "\(String(format: "%.2f", $0.coverage))%")
                ].compactMap { $0 }
        }

        table.print(sourceCoverages, style: Simple.self)
        table.print(testCoverages, style: Simple.self)
    }
}

let codecovCLI = CLI(singleCommand: StatsCommand())
let _ = codecovCLI.go()
