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

protocol DeviceDetailsViewActions {
    func fetchCertificate() async -> E2eIdentityCertificate?
    func showCertificate(_ certificate: String)
    func removeDevice() async -> Bool
    func resetSession() async -> Bool
    func updateVerified(_ value: Bool) async -> Bool
    var isProcessing: ((Bool) -> Void)? { get set }
    func copyToClipboard(_ value: String)
}

final class DeviceInfoViewModel: ObservableObject {
    let userSession: UserSession
    let addedDate: String
    let proteusID: String
    let getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol
    let userClient: UserClient

    var isE2EIdentityEnabled: Bool
    var isSelfClient: Bool
    var title: String

    var isValidCerificate: Bool {
        guard let certificate = e2eIdentityCertificate,
           E2EIdentityCertificateStatus.status(for: certificate.certificateStatus) != .none,
              E2EIdentityCertificateStatus.status(for: certificate.certificateStatus) != .notActivated else {
            return false
        }
        return true
    }

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
    private var actionsHandler: any DeviceDetailsViewActions
    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }
    @Published var isRemoved: Bool = false
    @Published var isReset: Bool = false
    @Published var isProteusVerificationEnabled: Bool = false
    @Published var isActionInProgress: Bool = false
    @Published var proteusKeyFingerprint: String = ""

    init(
        title: String,
        addedDate: String,
        proteusID: String,
        isProteusVerificationEnabled: Bool,
        actionsHandler: any DeviceDetailsViewActions,
        isE2EIdentityEnabled: Bool,
        isSelfClient: Bool,
        userSession: UserSession,
        getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol,
        userClient: UserClient
    ) {
        self.title = title
        self.addedDate = addedDate
        self.proteusID = proteusID
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.isE2EIdentityEnabled = isE2EIdentityEnabled
        self.userSession = userSession
        self.isSelfClient = isSelfClient
        self.getUserClientFingerprint = getUserClientFingerprint
        self.userClient = userClient
        self.actionsHandler.isProcessing = {[weak self] isProcessing in
            RunLoop.main.perform {
                self?.isActionInProgress = isProcessing
            }
        }
    }

    func fetchFingerPrintForProteus() async {
        DispatchQueue.main.async {
            self.isActionInProgress = true
        }
        guard let data = await getUserClientFingerprint.invoke(userClient: userClient),
                let fingerPrint = String(data: data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async {
            self.proteusKeyFingerprint = fingerPrint.splitStringIntoLines(charactersPerLine: 16).uppercased()
            self.isActionInProgress = false
        }
    }

    func fetchE2eCertificate() async {
        DispatchQueue.main.async {
            self.isActionInProgress = true
        }
        let certificate = await actionsHandler.fetchCertificate()
        DispatchQueue.main.async {
            self.e2eIdentityCertificate = certificate
            self.isActionInProgress = false
        }
    }

    func removeDevice() async {
        DispatchQueue.main.async {
            self.isActionInProgress = true
        }
        let isRemoved = await actionsHandler.removeDevice()
        DispatchQueue.main.async {
            self.isRemoved = isRemoved
            self.isActionInProgress = false
        }
    }

    func resetSession() async {
        DispatchQueue.main.async {
            self.isActionInProgress = true
        }
        let isReset =  await actionsHandler.resetSession()
        DispatchQueue.main.async {
            self.isReset = isReset
            self.isActionInProgress = false
        }
    }

    func updateVerifiedStatus(_ value: Bool) async {
        // TODO: Check why this is not working as expected
        let result = await actionsHandler.updateVerified(value)
        DispatchQueue.main.async {
            self.isProteusVerificationEnabled = result
        }
    }

    func copyToClipboard(_ value: String) {
        actionsHandler.copyToClipboard(value)
    }
}

extension DeviceInfoViewModel {
    static func map(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        getUserClientFingerprintUseCase: GetUserClientFingerprintUseCaseProtocol,
        e2eIdentityProvider: E2eIdentityProviding
    ) -> DeviceInfoViewModel {
        return DeviceInfoViewModel(
            title: userClient.model ?? "",
            addedDate: userClient.activationDate?.formattedDate ?? "",
            proteusID: userClient.proteusSessionID?.clientID.fingerprintStringWithSpaces.uppercased() ?? "",
            isProteusVerificationEnabled: userClient.verified,
            actionsHandler: DeviceDetailsViewActionsHandler(
                userClient: userClient,
                userSession: userSession,
                credentials: credentials,
                e2eIdentityProvider: e2eIdentityProvider
            ),
            isE2EIdentityEnabled: e2eIdentityProvider.isE2EIdentityEnabled,
            isSelfClient: userClient.isSelfClient(),
            userSession: userSession,
            getUserClientFingerprint: getUserClientFingerprintUseCase,
            userClient: userClient
        )
    }
}
