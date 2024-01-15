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
    var isSelfClient: Bool { get }
    var isProcessing: ((Bool) -> Void)? { get set }

    func fetchCertificate() async -> E2eIdentityCertificate?
    func removeDevice() async -> Bool
    func resetSession()
    func updateVerified(_ value: Bool) async -> Bool
    func copyToClipboard(_ value: String)
    func downloadE2EIdentityCertificate(certificate: E2eIdentityCertificate)
    func isE2eIdentityEnabled() async -> Bool
    func shouldCertificateBeUpdated(certificate: E2eIdentityCertificate) -> Bool
}

final class DeviceInfoViewModel: ObservableObject {
    let userSession: UserSession
    let addedDate: String
    let proteusID: String
    let getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol
    let userClient: UserClient
    var title: String

    var isSelfClient: Bool

    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }

    var isCertificateExpiringSoon: Bool? {
        guard let certificate = e2eIdentityCertificate else {
            return nil
        }
        return actionsHandler.shouldCertificateBeUpdated(certificate: certificate)
    }

    @Published
    var e2eIdentityCertificate: E2eIdentityCertificate?
    @Published var isRemoved: Bool = false
    @Published var isProteusVerificationEnabled: Bool = false
    @Published var isActionInProgress: Bool = false
    @Published var proteusKeyFingerprint: String = ""
    @Published var isE2eIdentityEnabled = false

    private var actionsHandler: any DeviceDetailsViewActions

    init(
        title: String,
        addedDate: String,
        proteusID: String,
        isProteusVerificationEnabled: Bool,
        actionsHandler: any DeviceDetailsViewActions,
        userSession: UserSession,
        getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol,
        userClient: UserClient,
        isSelfClient: Bool
    ) {
        self.title = title
        self.addedDate = addedDate
        self.proteusID = proteusID
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.userSession = userSession
        self.getUserClientFingerprint = getUserClientFingerprint
        self.userClient = userClient
        self.isSelfClient = isSelfClient
        self.actionsHandler.isProcessing = {[weak self] isProcessing in
            DispatchQueue.main.async {
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

    @MainActor
    func removeDevice() async {
        let isRemoved = await actionsHandler.removeDevice()
        self.isRemoved = isRemoved
    }

    func resetSession() {
        actionsHandler.resetSession()
    }

    func updateVerifiedStatus(_ value: Bool) async {
        let isVerified = await actionsHandler.updateVerified(value)
        await MainActor.run {
            isProteusVerificationEnabled = isVerified
        }
    }

    func copyToClipboard(_ value: String) {
        actionsHandler.copyToClipboard(value)
    }

    func downloadE2EIdentityCertificate() {
        guard let certificate = e2eIdentityCertificate else {
            return
        }
        actionsHandler.downloadE2EIdentityCertificate(certificate: certificate)
    }

    func isE2eIdenityEnabled() async -> Bool {
        let result = await actionsHandler.isE2eIdentityEnabled()
        await MainActor.run {
            self.isE2eIdentityEnabled = result
        }
        return result
    }

    func onAppear() {
        Task {
            _ = await isE2eIdenityEnabled()
            await fetchFingerPrintForProteus()
            await fetchE2eCertificate()
        }
    }
}

extension DeviceInfoViewModel {
    static func map(
        userClient: UserClient,
        isSelfClient: Bool,
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
                e2eIdentityProvider: e2eIdentityProvider,
                saveFileManager: SaveFileManager(systemFileSavePresenter: SystemSavePresenter()),
                mlsClientResolver: MLSClientResolver()
            ),
            userSession: userSession,
            getUserClientFingerprint: getUserClientFingerprintUseCase,
            userClient: userClient,
            isSelfClient: isSelfClient
        )
    }
}

extension E2eIdentityCertificate {

    var isValid: Bool {
        status == .valid
    }

}
