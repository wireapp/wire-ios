//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public struct AnalyticsEvent: Equatable, Sendable {

    /// A unique name.

    public let name: String

    /// Additional metadata.

    public let segmentation: Set<Segmentation>

    /// Create a new `AnalyticsEvent`.
    ///
    /// - Parameters:
    ///   - name: A unique name.
    ///   - segmentation: Additional metadata.

    public init(
        name: String,
        segmentation: some Collection<Segmentation> = []
    ) {
        self.name = name
        self.segmentation = Set(segmentation)
    }

}

// MARK: -

public extension AnalyticsEvent {

    /// Represents a key-value pair for analytics event segmentation.
    ///
    /// This struct is used to provide additional, structured information about an analytics event.
    /// Each ``Segmentation`` consists of a key (identifying the type of information) and a value
    /// (the actual data point).

    struct Segmentation: Hashable, Sendable {

        public let key: String
        public let value: String

        public init(key: String, value: String) {
            self.key = key
            self.value = value
        }

        public init(key: String, value: Int) {
            self.key = key
            self.value = "\(value)"
        }

        public init(key: String, value: Int32) {
            self.key = key
            self.value = "\(value)"
        }

        public init(key: String, value: Bool) {
            self.key = key
            self.value = value ? "True" : "False"
        }

    }

}

// MARK: -

extension AnalyticsEvent: CustomDebugStringConvertible {

    public var debugDescription: String {
        "event: \(name), segmentation: \(segmentation)"
    }

}
