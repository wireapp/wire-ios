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

import UIKit
import WireUtilities

// MARK: - BitRateStatus

enum BitRateStatus: String {
    case constant
    case variable

    fileprivate var localizedText: String {
        switch self {
        case .constant:
            L10n.Localizable.Call.Status.constantBitrate

        /// We don't need to display the `Variable Bit Rate` label, because it's the default.
        case .variable:
            ""
        }
    }

    fileprivate var accessibilityValue: String {
        rawValue
    }

    init(_ isConstantBitRate: Bool) {
        self = isConstantBitRate ? .constant : .variable
    }
}

// MARK: - BitRateLabel

final class BitRateLabel: DynamicFontLabel {
    var bitRateStatus: BitRateStatus? {
        didSet {
            updateLabel()
        }
    }

    private func updateLabel() {
        text = bitRateStatus?.localizedText
        accessibilityValue = bitRateStatus?.accessibilityValue
    }
}
