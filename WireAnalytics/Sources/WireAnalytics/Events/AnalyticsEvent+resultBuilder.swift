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

// Allows for writing the event initialization with segmentations more compact.

public extension AnalyticsEvent {

    @resultBuilder
    struct SegmentationEntryBuilder {

        public static func buildBlock(_ components: [SegmentationEntry]...) -> [SegmentationEntry] {
            components.flatMap { $0 }
        }

        public static func buildExpression(_ expression: SegmentationEntry) -> [SegmentationEntry] {
            [expression]
        }

        public static func buildExpression(_ expression: [SegmentationEntry]) -> [SegmentationEntry] {
            expression
        }

        public static func buildOptional(_ components: [SegmentationEntry]?) -> [SegmentationEntry] {
            components ?? []
        }

        public static func buildEither(first components: [SegmentationEntry]) -> [SegmentationEntry] {
            components
        }

        public static func buildEither(second components: [SegmentationEntry]) -> [SegmentationEntry] {
            components
        }
    }

    /// Create a new `AnalyticsEvent`.
    ///
    /// - Parameters:
    ///   - name: A unique name.
    ///   - segmentation: Additional metadata.

    init(
        name: String,
        @SegmentationEntryBuilder segmentation: () -> [SegmentationEntry]
    ) {
        self.init(
            name: name,
            segmentation: segmentation()
        )
    }
}
