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
import WireDataModel

struct ClientTableViewCellModel {
    let title: String
    let proteusLabelText: String
    let mlsThumbprintLabelText: String
    let isProteusVerified: Bool
    let e2eIdentityStatus: E2EIdentityCertificateStatus?
    let activationDate: Date?

    private typealias DeviceDetailsSection = L10n.Localizable.Device.Details.Section

    init(title: String,
         proteusLabelText: String,
         mlsThumbprintLabelText: String,
         isProteusVerified: Bool,
         e2eIdentityStatus: E2EIdentityCertificateStatus?,
         activationDate: Date?) {
        self.title = title
        self.proteusLabelText = proteusLabelText
        self.mlsThumbprintLabelText = mlsThumbprintLabelText
        self.isProteusVerified = isProteusVerified
        self.e2eIdentityStatus = e2eIdentityStatus
        self.activationDate = activationDate
    }

    init(userClient: UserClientType,
         shouldSetType: Bool = true) {
        if shouldSetType {
            title = userClient.deviceClass == .legalHold ?
            L10n.Localizable.Device.Class.legalhold :
            (userClient.deviceClass?.localizedDescription.capitalized ?? userClient.type.localizedDescription.capitalized)
        } else {
            title = userClient.model ?? ""
        }
        let proteusId = userClient.displayIdentifier.fingerprintStringWithSpaces.uppercased()
        proteusLabelText = DeviceDetailsSection.Proteus.value(proteusId)
        isProteusVerified = userClient.verified
        let mlsThumbPrint = userClient.mlsThumbPrint?.fingerprintStringWithSpaces ?? ""
        mlsThumbprintLabelText = !mlsThumbPrint.isEmpty ? DeviceDetailsSection.Mls.thumbprint(mlsThumbPrint) : ""
        e2eIdentityStatus = userClient.e2eIdentityCertificate?.status
        activationDate = userClient.activationDate
    }
}
