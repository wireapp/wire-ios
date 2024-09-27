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

import CoreGraphics

// MARK: - StyleKitIcon.Size

extension StyleKitIcon {
    /// Represents the target size of an icon. You can either use standard values,
    /// or use a raw CGFloat value, without needing to add another case.

    public enum Size: ExpressibleByIntegerLiteral, RawRepresentable {
        /// 8pt
        case nano
        /// 16pt.
        case tiny
        /// 20pt.
        case small
        /// 24pt.
        case medium
        /// 48pt.
        case large
        /// A custom size.
        case custom(CGFloat)

        // MARK: - Literal Conversion

        public init(floatLiteral value: CGFloat) {
            self = .custom(value)
        }

        public init(integerLiteral value: Int) {
            self = .custom(CGFloat(value))
        }

        public init?(rawValue: CGFloat) {
            self.init(floatLiteral: rawValue)
        }

        // MARK: - CGFloat Conversion

        /// The value to use to generate the icon.
        public var rawValue: CGFloat {
            switch self {
            case .nano: 8
            case .tiny: 16
            case .small: 20
            case .medium: 24
            case .large: 48
            case let .custom(value): value
            }
        }
    }
}

extension StyleKitIcon.Size {
    public var cgSize: CGSize {
        .init(width: rawValue, height: rawValue)
    }
}
