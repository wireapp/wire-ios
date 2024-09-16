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

import Foundation

public protocol LoggerProtocol {

    func debug(_ message: any LogConvertible, attributes: LogAttributes...)
    func info(_ message: any LogConvertible, attributes: LogAttributes...)
    func notice(_ message: any LogConvertible, attributes: LogAttributes...)
    func warn(_ message: any LogConvertible, attributes: LogAttributes...)
    func error(_ message: any LogConvertible, attributes: LogAttributes...)
    func critical(_ message: any LogConvertible, attributes: LogAttributes...)

    var logFiles: [URL] { get }

    /// Add an attribute, value to each logs - DataDog only
    func addTag(_ key: LogAttributesKey, value: String?)
}

extension LoggerProtocol {

    func attributesDescription(from attributes: LogAttributes) -> String {
        var logAttributes = attributes

        // drop attributes used for visibility and category
        logAttributes.removeValue(forKey: LogAttributesKey.public)
        logAttributes.removeValue(forKey: LogAttributesKey.tag)

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
    public func flattenArray(_ attributes: [LogAttributes]) -> LogAttributes {
        var mergedAttributes: LogAttributes = [:]
        attributes.forEach {
            mergedAttributes.merge($0) { _, new in new }
        }
        return mergedAttributes
    }
}
