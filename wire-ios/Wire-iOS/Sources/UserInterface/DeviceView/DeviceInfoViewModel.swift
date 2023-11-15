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
import WireCommonComponents

struct E2EIdentityCertificate {
    var status: E2EIdentityCertificateStatus
    var serialNumber: String
    var certificate: String
    var exipirationDate: Date
    var isExpiringSoon: Bool {
        Date.now.timeIntervalSince(exipirationDate) < .oneWeek // TODO: check this logic
    }
}

extension E2EIdentityCertificate {
    var isValidCertificate: Bool {
        return !certificate.isEmpty && exipirationDate < Date.now
    }
}

enum E2EIdentityCertificateStatus: CaseIterable {
    case notActivated, revoked, expired, valid, none
}

extension E2EIdentityCertificateStatus {
    func titleForStatus() -> String {
        switch self {
        case .notActivated:
            return L10n.Localizable.Device.Details.Not.activated
        case .revoked:
            return L10n.Localizable.Device.Details.revoked
        case .expired:
            return L10n.Localizable.Device.Details.expired
        case .valid:
            return L10n.Localizable.Device.Details.valid
        case .none:
            return ""
        }
    }

    func imageForStatus() -> Image {
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
            return Image(.certificateRevoked)
        }
    }
}

protocol DeviceDetailsViewActions {
    func fetchCertificate() async
    func showCertificate(_ certificate: String)
    func removeDevice()
    func resetSession()
    func setVerified(_ value: Bool)
    func copyToClipboard(_ value: String)
}

struct DeviceInfoViewModel {
    let udid: String
    let addedDate: String = Date().formattedDate
    var title: String
    let mlsThumbprint: String
    let deviceKeyFingerprint: String
    let proteusID: String
    var isProteusVerificationEnabled: Bool
    var e2eIdentityCertificate: E2EIdentityCertificate
    let actionsHandler: DeviceDetailsViewActions

    init(
        udid: String,
        title: String,
        mlsThumbprint: String,
        deviceKeyFingerprint: String,
        proteusID: String,
        isProteusVerificationEnabled: Bool,
        e2eIdentityCertificate: E2EIdentityCertificate,
        actionsHandler: DeviceDetailsViewActions = DeviceDetailsActionsHandler()
    ) {
        self.udid = udid
        self.title = title
        self.mlsThumbprint = mlsThumbprint
        self.deviceKeyFingerprint = deviceKeyFingerprint
        self.proteusID = proteusID
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.e2eIdentityCertificate = e2eIdentityCertificate
        self.actionsHandler = actionsHandler
        #if DEBUG
        FontScheme.configure(with: .large)
        #endif
    }
}

extension DeviceInfoViewModel: Identifiable {
    var id: String {
        return udid
    }
}

struct DevicesViewModel {
    var currentDevice: DeviceInfoViewModel
    var otherDevices: [DeviceInfoViewModel]

    func onRemoveDevice(_ indexSet: IndexSet) {

    }
}
