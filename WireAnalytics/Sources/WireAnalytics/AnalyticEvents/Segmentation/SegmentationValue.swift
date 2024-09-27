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

/// Represents a key-value pair for analytics event segmentation.
///
/// This struct is used to provide additional, structured information about an analytics event.
/// Each `SegmentationValue` consists of a key (identifying the type of information) and a value
/// (the actual data point).
///
/// - Note: This struct conforms to `Hashable`, allowing it to be used in sets and as dictionary keys.
public struct SegmentationValue: Hashable {

    let key: String
    let value: String

}
