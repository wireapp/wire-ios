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
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - AvailabilityLabelStyle

enum AvailabilityLabelStyle: Int {
    case list, participants
}

extension Availability {
    var localizedName: String {
        switch self {
        case .none:
            L10n.Localizable.Availability.none
        case .available:
            L10n.Localizable.Availability.available
        case .away:
            L10n.Localizable.Availability.away
        case .busy:
            L10n.Localizable.Availability.busy
        }
    }

    var iconType: StyleKitIcon? {
        switch self {
        case .none:
            nil
        case .available:
            .statusAvailable
        case .away:
            .statusAway
        case .busy:
            .statusBusy
        }
    }
}
