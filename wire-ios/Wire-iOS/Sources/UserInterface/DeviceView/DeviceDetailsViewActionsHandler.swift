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

import UIKit
import WireDataModel
import WireSyncEngine

final class DeviceDetailsViewActionsHandler: DeviceDetailsViewActions, ObservableObject {
    let logger = WireLogger.e2ei
    var userClient: UserClient
    var userSession: UserSession
    var clientRemovalObserver: ClientRemovalObserver?
    var credentials: UserEmailCredentials?
    let getProteusFingerprint: GetUserClientFingerprintUseCaseProtocol
    private let contextProvider: ContextProvider
    private let e2eiCertificateEnrollment: EnrollE2EICertificateUseCaseProtocol

    var isProcessing: ((Bool) -> Void)?

    var isSelfClient: Bool {
        userClient.isSelfClient()
    }

    private var saveFileManager: SaveFileActions

    init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: UserEmailCredentials?,
        saveFileManager: SaveFileActions,
        getProteusFingerprint: GetUserClientFingerprintUseCaseProtocol,
        contextProvider: ContextProvider,
        e2eiCertificateEnrollment: EnrollE2EICertificateUseCaseProtocol
    ) {
        self.userClient = userClient
        self.credentials = credentials
        self.userSession = userSession
        self.saveFileManager = saveFileManager
        self.getProteusFingerprint = getProteusFingerprint
        self.contextProvider = contextProvider
        self.e2eiCertificateEnrollment = e2eiCertificateEnrollment
    }

    @MainActor
    func enrollClient() async throws -> String {
        do {
            return try await startE2EIdentityEnrollment()
        } catch {
            logger.error(error.localizedDescription)
            throw error
        }
    }

    @MainActor
    func removeDevice() async -> Bool {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: false)
            }

            clientRemovalObserver = ClientRemovalObserver(
                userClientToDelete: userClient,
                delegate: self,
                credentials: credentials
            ) { [logger] error in
                if let error {
                    logger.error("failed to remove client: \(String(reflecting: error))")
                    continuation.resume(returning: false)
                } else {
                    continuation.resume(returning: true)
                }
            }
            clientRemovalObserver?.startRemoval()
        }
    }

    func resetSession() {
        userClient.resetSession()
    }

    @MainActor
    func updateVerified(_ isVerified: Bool) async -> Bool {
        let selfUserClient = userSession.selfUserClient
        return await withCheckedContinuation { continuation in
            userSession.enqueue({
                if isVerified {
                    selfUserClient?.trustClient(self.userClient)
                } else {
                    selfUserClient?.ignoreClient(self.userClient)
                }
            }, completionHandler: {
                continuation.resume(returning: self.userClient.verified)
            })
        }
    }

    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
    }

    func downloadE2EIdentityCertificate(certificate: E2eIdentityCertificate) {
        saveFileManager.save(
            value: certificate.details,
            fileName: userClient.label ?? "e2ecertificate",
            type: "txt"
        )
    }

    @MainActor
    func getProteusFingerPrint() async -> String {
        guard let data = await getProteusFingerprint.invoke(userClient: userClient) else {
            logger.error("Valid fingerprint data is missing")
            return ""
        }
        let fingerPrint = String(decoding: data, as: UTF8.self)
        return fingerPrint.splitStringIntoLines(charactersPerLine: 16).uppercased()
    }

    @MainActor
    private func startE2EIdentityEnrollment() async throws -> String {
        guard let topmostViewController = UIApplication.shared.topmostViewController() else {
            let errorDescription = "Failed to fetch RootViewController instance"
            logger.error(errorDescription)
            throw DeviceDetailsActionsError.failedAction(errorDescription)
        }
        let oauthUseCase = OAuthUseCase(targetViewController: { topmostViewController })
        return try await e2eiCertificateEnrollment.invoke(
            authenticate: oauthUseCase.invoke
        )
    }

    @MainActor
    private func fetchE2eIdentityCertificate() async throws -> E2eIdentityCertificate? {
        guard let mlsClientID = MLSClientID(userClient: userClient),
              let mlsGroupId = await fetchSelfConversationMLSGroupID() else {
            logger.error("MLSGroupID for self was not found")
            return nil
        }
        return try await userSession.getE2eIdentityCertificates.invoke(
            mlsGroupId: mlsGroupId,
            clientIds: [mlsClientID]
        ).first
    }

    @MainActor
    private func fetchSelfConversationMLSGroupID() async -> MLSGroupID? {
        await contextProvider.syncContext.perform { [weak self] in
            guard let self else {
                return nil
            }
            return ZMConversation.fetchSelfMLSConversation(in: contextProvider.syncContext)?.mlsGroupID
        }
    }
}

extension DeviceDetailsViewActionsHandler: ClientRemovalObserverDelegate {
    func present(
        _ clientRemovalObserver: ClientRemovalObserver,
        viewControllerToPresent: UIViewController
    ) {
        if !(UIApplication.shared.topmostViewController()?.presentedViewController is UIAlertController) {
            UIViewController.presentTopMost(viewController: viewControllerToPresent)
        }
    }

    func setIsLoadingViewVisible(
        _ clientRemovalObserver: ClientRemovalObserver,
        isVisible: Bool
    ) {
        isProcessing?(isVisible)
    }
}

enum DeviceDetailsActionsError: Error {
    case failedAction(String)
}
