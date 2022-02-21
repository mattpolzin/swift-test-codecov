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
    public let data: [Data]

    public func fileCoverages(for property: AggregateProperty) -> [String: File.Coverage] {
        return Dictionary(uniqueKeysWithValues: data
            .first!
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
