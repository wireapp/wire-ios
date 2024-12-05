//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

public import Foundation

//public typealias LoggerProtocol = LegacyLoggerProtocol

public protocol LegacyLoggerProtocol {

    func debug(_ message: any LegacyLogConvertible, attributes: LegacyLogAttributes...)
    func info(_ message: any LegacyLogConvertible, attributes: LegacyLogAttributes...)
    func notice(_ message: any LegacyLogConvertible, attributes: LegacyLogAttributes...)
    func warn(_ message: any LegacyLogConvertible, attributes: LegacyLogAttributes...)
    func error(_ message: any LegacyLogConvertible, attributes: LegacyLogAttributes...)
    func critical(_ message: any LegacyLogConvertible, attributes: LegacyLogAttributes...)

    var logFiles: [URL] { get }

    /// Add an attribute, value to each logs - DataDog only
    func addTag(_ key: LegacyLogAttributesKey, value: String?)
}

public extension LoggerProtocol {

    func attributesDescription(from attributes: LegacyLogAttributes) -> String {
        var logAttributes = attributes

        // drop attributes used for visibility and category
        logAttributes.removeValue(forKey: LegacyLogAttributesKey.public)
        logAttributes.removeValue(forKey: LegacyLogAttributesKey.tag)

        guard !logAttributes.isEmpty else {
            return ""
        }

        var description = " - ["
        description += logAttributes.keys.sorted().map { key in
            "\(key.rawValue): \(logAttributes[key] ?? "<nil>")"
        }.joined(separator: ", ")
        description += "]"

        return description
    }

    /// helper method to transform attributes array to single LogAttributes
    /// - note: if same key is contained accross multiple attributes, the latest one is taken
    func flattenArray(_ attributes: [LegacyLogAttributes]) -> LegacyLogAttributes {
        var mergedAttributes: LegacyLogAttributes = [:]
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }
        return mergedAttributes
    }
}
