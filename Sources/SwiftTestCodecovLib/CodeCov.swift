//
//  CodeCov.swift
//  
//
//  Created by Mathew Polzin on 8/1/19.
//

import Foundation

/// A Decodable representation of the JSON that
/// `swift test --enable-code-coverage` outputs.
public struct CodeCov: Decodable {
    
    public let version: String
    public let type: String
    public let data: [Data]

    public func fileCoverages(for property: AggregateProperty) -> [String: File.Coverage] {
        guard let first = data.first else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: first
            .files
            .map { ($0.filename, $0.summary.coverage(for: property)) }
        )
    }

    public struct Data: Decodable {
        public let files: [File]
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

        public struct Coverage: Codable, Equatable {
            public let count: Int
            public let covered: Int
            public let percent: Double
        }
    }

    public enum AggregateProperty: String, RawRepresentable, CaseIterable, Codable {
        case lines
        case functions
        case instantiations
    }
}

extension CodeCov.File.Coverage {
    /// Internal constructor for use in Unit Tests
    internal init(
        count: Int = 0,
        covered: Int = 0
    ) {
        self.count = count
        self.covered = covered
        self.percent = Double(covered) / Double(count) * 100.0
    }
}

extension CodeCov.AggregateProperty: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}
