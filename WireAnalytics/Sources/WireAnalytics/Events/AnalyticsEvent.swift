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

/// An event that can be tracked.

public struct AnalyticsEvent: Equatable, Identifiable, Sendable {

    public var id: String { name }

    /// A unique name.

    let name: String

    /// Additional metadata.

    let segmentation: Set<SegmentationEntry>

    /// Create a new `AnalyticsEvent`.
    ///
    /// - Parameters:
    ///   - name: A unique name.
    ///   - segmentation: Additional metadata.

    public init<Collection>(
        name: String,
        segmentation: Collection = []
    ) where Collection: Swift.Collection, Collection.Element == SegmentationEntry {
        self.name = name
        self.segmentation = Set(segmentation)
    }
}

extension AnalyticsEvent: CustomDebugStringConvertible {

    public var debugDescription: String {
        "event: \(name), segmentation: \(segmentation)"
    }

}

// MARK: - SegmentationEntry @resultBuilder

extension AnalyticsEvent {

    @resultBuilder
    public struct SegmentationEntryBuilder {
        public static func buildBlock(_ components: SegmentationEntry...) -> [SegmentationEntry] {
            components
        }
    }

    /// Create a new `AnalyticsEvent`.
    ///
    /// - Parameters:
    ///   - name: A unique name.
    ///   - segmentation: Additional metadata.

    public init(
        _ name: String,
        @SegmentationEntryBuilder segmentation: () -> [SegmentationEntry]
    ) {
        self.init(
            name: name,
            segmentation: segmentation()
        )
    }
}
