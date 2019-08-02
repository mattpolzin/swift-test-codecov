
import Foundation
import swiftTestCodecovLib

let jsonDecoder = JSONDecoder()

let path = CommandLine.arguments[1]

let aggProperty: CodeCov.AggregateProperty = CommandLine.arguments.count > 2
    ? CodeCov.AggregateProperty(rawValue: CommandLine.arguments[2]) ?? .lines
    : .lines

let data = try! Data(contentsOf: URL(fileURLWithPath: path))

let codeCoverage = try! jsonDecoder.decode(CodeCov.self, from: data)

let coveragePerFile = codeCoverage.fileCoverages(for: aggProperty)

let totalCountOfProperty = coveragePerFile.reduce(0, {tot, next in
    tot + next.value.count
})

let overallCoverage = coveragePerFile.reduce(0.0, { avg, next in
    avg + Double(next.value.covered) / Double(totalCountOfProperty)
})

let overallCoveragePercent = overallCoverage * 100

print("\(String(format: "%.2f", overallCoveragePercent)) %")
