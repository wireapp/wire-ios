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
    let mlsCiphersuite: MLSCipherSuite?

    let title: String
    var isSelfClient: Bool
    var userClient: UserClientType

    var isCopyEnabled: Bool {
        Settings.isClipboardEnabled
    }

    var isCertificateExpiringSoon: Bool? {
        guard let certificate = e2eIdentityCertificate else {
            return nil
        }
        return certificate.shouldUpdate(with: gracePeriod)
    }

    var isE2eIdentityEnabled: Bool {
        e2eIdentityCertificate != nil && mlsThumbprint != nil
    }

    var mlsThumbprint: String? {
        e2eIdentityCertificate?
            .mlsThumbprint
            .splitStringIntoLines(charactersPerLine: 16)
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
    let isDebugMenuAvailable: Bool
    @Published var isDebugMenuPresented = false

    init(
        title: String,
        addedDate: String,
        proteusID: String,
        userClient: UserClientType,
        isSelfClient: Bool,
        gracePeriod: TimeInterval,
        mlsCiphersuite: MLSCipherSuite?,
        isFromConversation: Bool,
        actionsHandler: DeviceDetailsViewActions,
        conversationClientDetailsActions: ConversationUserClientDetailsActions,
        debugMenuActionsHandler: ConversationUserClientDetailsDebugActions? = nil,
        isDebugMenuAvailable: Bool
    ) {
        self.title = title
        self.addedDate = addedDate
        self.proteusID = proteusID
        self.actionsHandler = actionsHandler
        self.userClient = userClient
        self.isSelfClient = isSelfClient
        self.gracePeriod = gracePeriod
        self.mlsCiphersuite = mlsCiphersuite
        self.isFromConversation = isFromConversation
        self.conversationClientDetailsActions = conversationClientDetailsActions
        self.debugMenuActionsHandler = debugMenuActionsHandler
        self.isDebugMenuAvailable = isDebugMenuAvailable

        self.actionsHandler.isProcessing = { [weak self] isProcessing in
            DispatchQueue.main.async {
                self?.isActionInProgress = isProcessing
            }
        }

        e2eIdentityCertificate = userClient.e2eIdentityCertificate
        isProteusVerificationEnabled = userClient.verified
    }

    func update(from userClient: UserClientType) {
        e2eIdentityCertificate = userClient.e2eIdentityCertificate
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
