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

import SwiftUI
import WireDataModel

extension E2EIdentityCertificateStatus {
    var title: String {
        switch self {
        case .notActivated:
            L10n.Localizable.Device.Details.Section.E2ei.Status.notActivated
        case .revoked:
            L10n.Localizable.Device.Details.Section.E2ei.Status.revoked
        case .expired:
            L10n.Localizable.Device.Details.Section.E2ei.Status.expired
        case .invalid:
            L10n.Localizable.Device.Details.Section.E2ei.Status.invalid
        case .valid:
            L10n.Localizable.Device.Details.Section.E2ei.Status.valid
        }
    }

    var image: Image? {
        switch self {
        case .notActivated:
            Image(.certificateExpired)
        case .revoked:
            Image(.certificateRevoked)
        case .expired:
            Image(.certificateExpired)
        case .invalid:
            Image(.certificateRevoked)
        case .valid:
            Image(.certificateValid)
        }
    }

    var uiImage: UIImage? {
        switch self {
        case .notActivated:
            .init(resource: .certificateExpired)
        case .revoked:
            .init(resource: .certificateRevoked)
        case .expired:
            .init(resource: .certificateExpired)
        case .invalid:
            .init(resource: .certificateRevoked)
        case .valid:
            .init(resource: .certificateValid)
        }
    }
}
