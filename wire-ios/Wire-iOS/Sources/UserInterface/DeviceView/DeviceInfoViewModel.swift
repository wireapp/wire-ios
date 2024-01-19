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

    func getCertificate() async -> E2eIdentityCertificate?
    func enrollClient() async -> E2eIdentityCertificate?
    func updateCertificate() async -> E2eIdentityCertificate?
    func removeDevice() async -> Bool
    func resetSession()
    func updateVerified(_ value: Bool) async -> Bool
    func copyToClipboard(_ value: String)
    func downloadE2EIdentityCertificate(certificate: E2eIdentityCertificate)
    func isE2eIdentityEnabled() async -> Bool
    func getProteusFingerPrint() async -> String
}

final class DeviceInfoViewModel: ObservableObject {
    let addedDate: String
    let proteusID: String
    let userClient: UserClient
    let gracePeriod: TimeInterval
    let mlsThumbprint: String?

    var title: String
    var isSelfClient: Bool

    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }

    var isCertificateExpiringSoon: Bool? {
        guard let certificate = e2eIdentityCertificate else {
            return nil
        }
        return certificate.shouldUpdate(with: gracePeriod)
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
        mlsThumbprint: String?,
        isProteusVerificationEnabled: Bool,
        actionsHandler: any DeviceDetailsViewActions,
        userClient: UserClient,
        isSelfClient: Bool,
        gracePeriod: TimeInterval
    ) {
        self.title = title
        self.addedDate = addedDate
        self.proteusID = proteusID
        self.mlsThumbprint = mlsThumbprint
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.userClient = userClient
        self.isSelfClient = isSelfClient
        self.gracePeriod = gracePeriod
        self.actionsHandler.isProcessing = {[weak self] isProcessing in
            DispatchQueue.main.async {
                self?.isActionInProgress = isProcessing
            }
        }
    }

    @MainActor
    func getE2eCertificate() async {
        self.isActionInProgress = true
        let certificate = await actionsHandler.getCertificate()
        self.e2eIdentityCertificate = certificate
        self.isActionInProgress = false
    }

    @MainActor
    func updateCertificate() async {
        self.isActionInProgress = true
        let certificate = await actionsHandler.updateCertificate()
        self.e2eIdentityCertificate = certificate
        self.isActionInProgress = false
    }

    @MainActor
    func enrollClient() async {
        self.isActionInProgress = true
        let certificate = await actionsHandler.enrollClient()
        self.e2eIdentityCertificate = certificate
        self.isActionInProgress = false
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

    @MainActor
    func isE2eIdenityEnabled() async {
        let result = await actionsHandler.isE2eIdentityEnabled()
        self.isE2eIdentityEnabled = result
    }

    @MainActor
    func getProteusFingerPrint() async {
        let result = await actionsHandler.getProteusFingerPrint()
        self.proteusKeyFingerprint = result
    }

    func onAppear() {
        Task {
            await isE2eIdenityEnabled()
            await getE2eCertificate()
            await getProteusFingerPrint()
        }
    }
}

extension DeviceInfoViewModel {
    static func map(
        userClient: UserClient,
        title: String,
        addedDate: String,
        proteusID: String?,
        isSelfClient: Bool,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        gracePeriod: TimeInterval,
        mlsGroupId: MLSGroupID?,
        mlsThumbprint: String?,
        getE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol,
        getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol,
        getProteusFingerprint: GetUserClientFingerprintUseCaseProtocol
    ) -> DeviceInfoViewModel {
        return DeviceInfoViewModel(
            title: title,
            addedDate: addedDate,
            proteusID: proteusID?.uppercased().fingerprintStringWithSpaces ?? "",
            mlsThumbprint: mlsThumbprint,
            isProteusVerificationEnabled: userClient.verified,
            actionsHandler: DeviceDetailsViewActionsHandler(
                userClient: userClient,
                userSession: userSession,
                credentials: credentials,
                mlsGroupId: mlsGroupId,
                saveFileManager: SaveFileManager(systemFileSavePresenter: SystemSavePresenter()),
                mlsClientResolver: MLSClientResolver(),
                getE2eIdentityEnabled: getE2eIdentityEnabled,
                getE2eIdentityCertificates: getE2eIdentityCertificates,
                getProteusFingerprint: getProteusFingerprint
            ),
            userClient: userClient,
            isSelfClient: isSelfClient,
            gracePeriod: gracePeriod
        )
    }
}

extension E2eIdentityCertificate {

    // current default days the certificate is retained on server
    private var kServerRetainedDays: Double { 28 * 24 * 60 * 60 }

    // Randomising time so that not all clients update certificate at the same time
    private var kRandomInterval: Double { Double(Int.random(in: 0..<86400)) }

    var isExpired: Bool {
        return expiryDate > Date.now
    }

    var isValid: Bool {
        status == .valid
    }

    var isActivated: Bool {
        return notValidBefore <= Date.now
    }

    var lastUpdateDate: Date {
        return notValidBefore + kServerRetainedDays + kRandomInterval
    }

    func shouldUpdate(with gracePeriod: TimeInterval) -> Bool {
        return isActivated && isExpired && (lastUpdateDate + gracePeriod) < Date.now
    }

}
