//
//  CodeCov.swift
//  
//
//  Created by Mathew Polzin on 8/1/19.
//

import Foundation

public struct CodeCov: Decodable {
    public let version: String
    public let type: String
    public var data: [Data]

    public func fileCoverages(for property: AggregateProperty) -> [String: File.Coverage] {
        return Dictionary(uniqueKeysWithValues: data
            .first!
            .files
            .map { ($0.filename, $0.summary.coverage(for: property)) }
        )
    }

    /// Removes all files containing "Tests" or "Test" in their names from coverage result
    public mutating func stripAllTestFiles() {
        var processedData = [Data]()
        for datum in data {
            var datumCopy = datum
            datumCopy.stripTestFiles()
            processedData.append(datumCopy)
        }
        self.data = processedData
    }

    public struct Data: Decodable {
        public var files: [File]

        /// Removes all files containing "Tests" or "Test" in their names from coverage result
        mutating func stripTestFiles() {
            files = files.filter({ file in
                !(file.filename.lowercased().contains("tests") || file.filename.lowercased().contains("test"))
            })
        }
    }

    public struct File: Decodable {
        public let filename: String
        public let summary: Summary

        public struct Summary: Decodable {
            public let lines: Coverage
            public let functions: Coverage
            public let instantiations: Coverage

            func coverage(for property: AggregateProperty) -> Coverage {
                switch property {
                case .lines:
                    return lines
                case .functions:
                    return functions
                case .instantiations:
                    return instantiations
                }
            }
        }

        public struct Coverage: Codable {
            public let count: Int
            public let covered: Int
            public let percent: Double
        }
    }

    public enum AggregateProperty: String, RawRepresentable, CaseIterable {
        case lines
        case functions
        case instantiations
    }
}

extension CodeCov.AggregateProperty: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}
