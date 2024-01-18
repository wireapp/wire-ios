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

import UIKit
import WireDataModel
import WireSyncEngine

final class DeviceDetailsViewActionsHandler: DeviceDetailsViewActions, ObservableObject {
    private let logger: LoggerProtocol
    private let mlsClientResolver: MLSClientResolving
    private let conversationId: Data?
    private var userClient: UserClient
    private var userSession: UserSession
    private var clientRemovalObserver: ClientRemovalObserver?
    private var credentials: ZMEmailCredentials?
    private let getE2eIdentityEnabled: GetIsE2EIdentityEnabledUsecaseProtocol
    private let getE2eIdentityCertificates: GetE2eIdentityCertificatesUsecaseProtocol
    private let getProteusFingerprint: GetUserClientFingerprintUseCaseProtocol

    var isProcessing: ((Bool) -> Void)?

    var isSelfClient: Bool {
        userClient.isSelfClient()
    }

    private var saveFileManager: SaveFileActions

    init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        conversationId: Data?,
        saveFileManager: SaveFileActions,
        logger: LoggerProtocol = WireLogger.e2ei,
        mlsClientResolver: MLSClientResolving,
        getE2eIdentityEnabled: GetIsE2EIdentityEnabledUsecaseProtocol,
        getE2eIdentityCertificates: GetE2eIdentityCertificatesUsecaseProtocol,
        getProteusFingerprint: GetUserClientFingerprintUseCaseProtocol
    ) {
        self.userClient = userClient
        self.credentials = credentials
        self.userSession = userSession
        self.saveFileManager = saveFileManager
        self.logger = logger
        self.mlsClientResolver = mlsClientResolver
        self.getE2eIdentityEnabled = getE2eIdentityEnabled
        self.getE2eIdentityCertificates = getE2eIdentityCertificates
        self.conversationId = conversationId
        self.getProteusFingerprint = getProteusFingerprint
    }

    func updateCertificate() async -> E2eIdentityCertificate? {
        // TODO: after this task https://wearezeta.atlassian.net/browse/WPB-6039
        return nil
    }

    func enrollClient() async -> E2eIdentityCertificate? {
        // TODO: after this task https://wearezeta.atlassian.net/browse/WPB-6039
        return nil
    }

    @MainActor
    func getCertificate() async -> E2eIdentityCertificate? {
        #if DEBUG
        if DeveloperDeviceDetailsSettingsSelectionViewModel.isE2eIdentityViewEnabled {
            return DeveloperDeviceDetailsSettingsSelectionViewModel.mockCertifiateForSelectedStatus()
        }
        #endif
        guard let mlsClientID = mlsClientResolver.mlsClientId(for: userClient), let conversationId = conversationId else {
            return nil
        }
        do {
            return try await getE2eIdentityCertificates.invoke(conversationId: conversationId, clientIds: [mlsClientID]) .first
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
            return nil
        }
    }

    func isE2eIdentityEnabled() async -> Bool {
        #if DEBUG
        if DeveloperDeviceDetailsSettingsSelectionViewModel.isE2eIdentityViewEnabled {
            return true
        }
        #endif
        do {
            return try await getE2eIdentityEnabled.invoke()
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
            return false
        }
    }

    @MainActor
    func removeDevice() async -> Bool {
        return await withCheckedContinuation {[weak self] continuation in
            guard let self = self else {
                return
            }
            // (Continuation)[https://developer.apple.com/documentation/swift/checkedcontinuation]
            // Using the same continuation twice results in a crash.
            var optionalContinuation: CheckedContinuation<Bool, Never>? = continuation
            clientRemovalObserver = ClientRemovalObserver(
                userClientToDelete: userClient,
                delegate: self,
                credentials: credentials,
                completion: {
                    error in
                    defer {
                        optionalContinuation = nil
                    }
                    optionalContinuation?.resume(returning: error == nil)
                    if let error = error {
                        WireLogger.e2ei.error(error.localizedDescription)
                    }
                }
            )
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
            }
            )
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
        guard let data = await getProteusFingerprint.invoke(userClient: userClient),
                let fingerPrint = String(data: data, encoding: .utf8) else {
            return ""
        }
        return fingerPrint.splitStringIntoLines(charactersPerLine: 16).uppercased()
    }
}

extension DeviceDetailsViewActionsHandler: ClientRemovalObserverDelegate {
    func present(
        _ clientRemovalObserver: ClientRemovalObserver,
        viewControllerToPresent: UIViewController
    ) {
        if !(UIApplication.shared.topmostViewController()?.presentedViewController is UIAlertController) {
                    UIViewController.presentTopmost(viewController: viewControllerToPresent)
        }
    }

    func setIsLoadingViewVisible(
        _ clientRemovalObserver: ClientRemovalObserver,
        isVisible: Bool
    ) {
        isProcessing?(isVisible)
    }
}
