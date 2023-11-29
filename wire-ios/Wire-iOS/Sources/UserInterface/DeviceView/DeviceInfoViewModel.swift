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
import WireDataModel
import WireSyncEngine

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

protocol DeviceDetailsViewActions {
    func fetchCertificate() async -> E2eIdentityCertificate?
    func showCertificate(
        _ certificate: String
    )
    func removeDevice() async -> Bool
    func resetSession() async -> Bool
    func updateVerified(_ value: Bool) async -> Bool
    func copyToClipboard(_ value: String)
}

final class DeviceInfoViewModel: ObservableObject {
    let userSession: UserSession
    let uuid: String
    let addedDate: String
    var title: String
    let deviceKeyFingerprint: String
    let proteusID: String
    var isProteusVerificationEnabled: Bool
    var isE2EIdentityEnabled: Bool
    var isSelfClient: Bool
    var certificateStatus: E2EIdentityCertificateStatus {
        guard let certificate = e2eIdentityCertificate,
                let status = E2EIdentityCertificateStatus.allCases.filter({
                        $0.titleForStatus() == certificate.certificateStatus
                    }
                ).first
        else {
            return isE2EIdentityEnabled ? .notActivated : .none
        }
        return status
    }

    var isCertificateExpiringSoon: Bool {
        guard let certificate = e2eIdentityCertificate else {
            return false
        }
        return certificate.expiryDate < Date.now + .oneDay + .oneDay
    }
    @Published var e2eIdentityCertificate: E2eIdentityCertificate?
    private let actionsHandler: any DeviceDetailsViewActions
    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }
    @Published var isRemoved: Bool = false
    @Published var isReset: Bool = false
    @Published var isVerified: Bool = false
    @Published var isActionInProgress: Bool = false

    init(
        uuid: String,
        title: String,
        addedDate: String,
        deviceKeyFingerprint: String,
        proteusID: String,
        isProteusVerificationEnabled: Bool,
        actionsHandler: any DeviceDetailsViewActions,
        isE2EIdentityEnabled: Bool,
        isSelfClient: Bool,
        userSession: UserSession
    ) {
        self.uuid = uuid
        self.title = title
        self.addedDate = addedDate
        self.deviceKeyFingerprint = deviceKeyFingerprint
        self.proteusID = proteusID
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
        self.userSession = userSession
        self.isSelfClient = isSelfClient
    }

    func fetchE2eCertificate() async {
        isActionInProgress = true
        e2eIdentityCertificate = await actionsHandler.fetchCertificate()
        isActionInProgress = false
    }

    func removeDevice() async {
        isActionInProgress = true
        isRemoved = await actionsHandler.removeDevice()
        isActionInProgress = false
    }

    func resetSession() async {
        isActionInProgress = true
        isReset = await actionsHandler.resetSession()
        isActionInProgress = false
    }

    func updateVerifiedStatus(
        _ value: Bool
    ) async {
        isActionInProgress = true
        isVerified = await actionsHandler.updateVerified(
            value
        )
        isActionInProgress = false
    }

    func copyToClipboard(
        _ value: String
    ) {
        actionsHandler.copyToClipboard(
            value
        )
    }
}

extension DeviceInfoViewModel: Identifiable {
    var id: String {
        return uuid
    }
}

extension DeviceInfoViewModel {
    static func map(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?
    ) -> DeviceInfoViewModel {
        return DeviceInfoViewModel(
            uuid: UUID().uuidString,
            title: userClient.model ?? "",
            addedDate: userClient.activationDate?.formattedDate ?? "",
            deviceKeyFingerprint: String(
                data: userClient.fingerprint ?? Data(),
                encoding: .utf8
            )?.splitStringIntoLines(
                charactersPerLine: 16
            ).uppercased() ?? "",
            proteusID: userClient.proteusSessionID?.clientID.fingerprintStringWithSpaces.uppercased() ?? "",
            isProteusVerificationEnabled: userClient.user?.isVerified ?? false,
            actionsHandler: DeviceDetailsViewActionsHandler(
                userClient: userClient,
                userSession: userSession,
                credentials: credentials
            ),
            isE2EIdentityEnabled: userClient.e2eIdentityProvider.isE2EIdentityEnabled,
            isSelfClient: userClient.isSelfClient(),
            userSession: userSession
        )
    }
}

struct DevicesViewModel {
    var currentDevice: DeviceInfoViewModel
    var otherDevices: [DeviceInfoViewModel]

    func onRemoveDevice(
        _ indexSet: IndexSet
    ) {

    }
}
