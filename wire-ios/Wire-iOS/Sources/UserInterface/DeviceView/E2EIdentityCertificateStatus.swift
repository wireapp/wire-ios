//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import SwiftUI

enum E2EIdentityCertificateStatus: CaseIterable {
    case notActivated, revoked, expired, valid, none
}

extension E2EIdentityCertificateStatus {
    func titleForStatus() -> String {
        switch self {
        case .notActivated:
            return L10n.Localizable.Device.Details.Section.E2e.Status.notactivated
        case .revoked:
            return L10n.Localizable.Device.Details.Section.E2e.Status.revoked
        case .expired:
            return L10n.Localizable.Device.Details.Section.E2e.Status.expired
        case .valid:
            return L10n.Localizable.Device.Details.Section.E2e.Status.valid
        case .none:
            return ""
        }
    }

    func imageForStatus() -> Image? {
        switch self {
        case .notActivated:
            return Image(.certificateExpired)
        case .revoked:
            return Image(.certificateRevoked)
        case .expired:
            return Image(.certificateExpired)
        case .valid:
            return Image(.certificateValid)
        case .none:
            return nil
        }
    }
}
