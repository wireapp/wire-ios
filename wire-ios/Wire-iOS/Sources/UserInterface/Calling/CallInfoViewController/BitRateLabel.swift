//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
import UIKit
import WireUtilities

enum BitRateStatus: String {
    case constant
    case variable

    /// We don't need to display the `Variable Bit Rate Encoding` label.
    fileprivate var localizedText: String {
        switch self {
        case BitRateStatus.constant:
            return L10n.Localizable.Call.Status.constantBitrate
        case BitRateStatus.variable:
            return ""
        }

    }

    fileprivate var accessibilityValue: String {
        return rawValue
    }

    init(_ isConstantBitRate: Bool) {
        self = isConstantBitRate ? .constant : .variable
    }
}

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
