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

// sourcery: AutoMockable
protocol DeviceDetailsViewActions {
    var isSelfClient: Bool { get }
    var isProcessing: ((Bool) -> Void)? { get set }

    /// Method to enroll and update E2E Identity certificates.
    /// - Returns: Certificate chain of all the clients
    func enrollClient() async throws -> String
    func removeDevice() async -> Bool
    func resetSession()
    func updateVerified(_ value: Bool) async -> Bool
    func copyToClipboard(_ value: String)
    func downloadE2EIdentityCertificate(certificate: E2eIdentityCertificate)
    func getProteusFingerPrint() async -> String
}

final class DeviceInfoViewModel: ObservableObject {
    let addedDate: String
    let proteusID: String
    let gracePeriod: TimeInterval
    let isFromConversation: Bool

    var mlsThumbprint: String?
    var title: String
    var isSelfClient: Bool
    var userClient: UserClient

    var isCopyEnabled: Bool {
        return Settings.isClipboardEnabled
    }

    var isCertificateExpiringSoon: Bool? {
        guard let certificate = e2eIdentityCertificate else {
            return nil
        }
        return certificate.shouldUpdate(with: gracePeriod)
    }

    var isE2eIdentityEnabled: Bool {
        return e2eIdentityCertificate != nil && mlsThumbprint != nil
    }

    var serialNumber: String? {
        e2eIdentityCertificate?.serialNumber
            .uppercased()
            .splitStringIntoLines(charactersPerLine: 16)
            .replacingOccurrences(of: " ", with: ":")
    }

    var showCertificateUpdateSuccess: ((String) -> Void)?

    @Published var e2eIdentityCertificate: E2eIdentityCertificate?
    @Published var shouldDismiss: Bool = false
    @Published var isProteusVerificationEnabled: Bool = false
    @Published var isActionInProgress: Bool = false
    @Published var proteusKeyFingerprint: String = ""
    @Published var showEnrollmentCertificateError = false

    var actionsHandler: DeviceDetailsViewActions
    var conversationClientDetailsActions: ConversationUserClientDetailsActions
    var debugMenuActionsHandler: ConversationUserClientDetailsDebugActions?
    let showDebugMenu: Bool

    init(
        certificate: E2eIdentityCertificate?,
        title: String,
        addedDate: String,
        proteusID: String,
        mlsThumbprint: String?,
        isProteusVerificationEnabled: Bool,
        userClient: UserClient,
        isSelfClient: Bool,
        gracePeriod: TimeInterval,
        isFromConversation: Bool,
        actionsHandler: DeviceDetailsViewActions,
        conversationClientDetailsActions: ConversationUserClientDetailsActions,
        debugMenuActionsHandler: ConversationUserClientDetailsDebugActions? = nil,
        showDebugMenu: Bool
    ) {
        self.e2eIdentityCertificate = certificate
        self.title = title
        self.addedDate = addedDate
        self.proteusID = proteusID
        self.mlsThumbprint = mlsThumbprint
        self.isProteusVerificationEnabled = isProteusVerificationEnabled
        self.actionsHandler = actionsHandler
        self.userClient = userClient
        self.isSelfClient = isSelfClient
        self.gracePeriod = gracePeriod
        self.isFromConversation = isFromConversation
        self.conversationClientDetailsActions = conversationClientDetailsActions
        self.debugMenuActionsHandler = debugMenuActionsHandler
        self.showDebugMenu = showDebugMenu
        self.actionsHandler.isProcessing = {[weak self] isProcessing in
            DispatchQueue.main.async {
                self?.isActionInProgress = isProcessing
            }
        }
    }

    func update(from userClient: UserClient) {
        e2eIdentityCertificate = userClient.e2eIdentityCertificate
        mlsThumbprint = userClient.resolvedMLSThumbprint?.splitStringIntoLines(charactersPerLine: 16)
        self.userClient = userClient
    }

    @MainActor
    func enrollClient() async {
        self.isActionInProgress = true
        do {
            let certificateChain = try await actionsHandler.enrollClient()
            showCertificateUpdateSuccess?(certificateChain)
        } catch {
            showEnrollmentCertificateError = true
        }
        self.isActionInProgress = false
    }

    @MainActor
    func removeDevice() async {
        self.shouldDismiss = await actionsHandler.removeDevice()
    }

    func resetSession() {
        actionsHandler.resetSession()
    }

    @MainActor
    func updateVerifiedStatus(_ value: Bool) async {
        isProteusVerificationEnabled = await actionsHandler.updateVerified(value)
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
    func getProteusFingerPrint() async {
        self.proteusKeyFingerprint = await actionsHandler.getProteusFingerPrint()
    }

    func onAppear() {
        Task {
            await getProteusFingerPrint()
        }
    }

    // MARK: ConversationUserClientDetailsActions

    func onShowMyDeviceTapped() {
        conversationClientDetailsActions.showMyDevice()
    }

    func onHowToDoThatTapped() {
        conversationClientDetailsActions.howToDoThat()
    }

    // MARK: ConversationUserClientDetailsDebugActions

    func onDeleteDeviceTapped() {
        Task {
            await debugMenuActionsHandler?.deleteDevice()
            await MainActor.run {
                shouldDismiss = true
            }
        }
    }

    func onCorruptSessionTapped() {
        Task {
            await debugMenuActionsHandler?.corruptSession()
            await MainActor.run {
                shouldDismiss = true
            }
        }
    }

    func onDuplicateClientTapped() {
        debugMenuActionsHandler?.duplicateClient()
    }
}

extension DeviceInfoViewModel {
    static func map(
        certificate: E2eIdentityCertificate?,
        userClient: UserClient,
        title: String,
        addedDate: String,
        proteusID: String?,
        isSelfClient: Bool,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        gracePeriod: TimeInterval,
        mlsThumbprint: String?,
        getProteusFingerprint: GetUserClientFingerprintUseCaseProtocol,
        saveFileManager: SaveFileActions = SaveFileManager(systemFileSavePresenter: SystemSavePresenter()),
        contextProvider: ContextProvider,
        e2eiCertificateEnrollment: EnrollE2EICertificateUseCaseProtocol,
        isFromConversation: Bool = false,
        showDebugMenu: Bool = Bundle.developerModeEnabled
    ) -> DeviceInfoViewModel {
        let deviceActionsHandler = DeviceDetailsViewActionsHandler(
            userClient: userClient,
            userSession: userSession,
            credentials: credentials,
            saveFileManager: saveFileManager,
            getProteusFingerprint: getProteusFingerprint,
            contextProvider: contextProvider,
            e2eiCertificateEnrollment: e2eiCertificateEnrollment
        )
        return DeviceInfoViewModel(
            certificate: certificate,
            title: title,
            addedDate: addedDate,
            proteusID: proteusID ?? "",
            mlsThumbprint: mlsThumbprint,
            isProteusVerificationEnabled: userClient.verified,
            userClient: userClient,
            isSelfClient: isSelfClient,
            gracePeriod: gracePeriod,
            isFromConversation: isFromConversation,
            actionsHandler: deviceActionsHandler,
            conversationClientDetailsActions: deviceActionsHandler,
            debugMenuActionsHandler: deviceActionsHandler,
            showDebugMenu: showDebugMenu
        )
    }
}

extension E2eIdentityCertificate {

    // current default days the certificate is retained on server
    private var kServerRetainedDays: Double { 28 * 24 * 60 * 60 }

    // Randomising time so that not all clients update certificate at the same time
    private var kRandomInterval: Double { Double(Int.random(in: 0..<86400)) }

    private var isExpired: Bool {
        return expiryDate > comparedDate
    }

    private var isValid: Bool {
        status == .valid
    }

    private var isActivated: Bool {
        return notValidBefore <= comparedDate
    }

    private var lastUpdateDate: Date {
        return notValidBefore + kServerRetainedDays + kRandomInterval
    }

    func shouldUpdate(with gracePeriod: TimeInterval) -> Bool {
        return isActivated && isExpired && (lastUpdateDate + gracePeriod) < comparedDate
    }
}
