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
    private let e2eIdentityProvider: E2eIdentityProviding
    private let userSession: UserSession
    private let mlsClientResolver: MLSClientResolving

    private var userClient: UserClient
    private var clientRemovalObserver: ClientRemovalObserver?
    private var credentials: ZMEmailCredentials?

    var isProcessing: ((Bool) -> Void)?

    var isSelfClient: Bool {
        userClient.isSelfClient()
    }

    private var saveFileManager: SaveFileActions

    init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        e2eIdentityProvider: E2eIdentityProviding,
        saveFileManager: SaveFileActions,
        logger: LoggerProtocol = WireLogger.e2ei,
        mlsClientResolver: MLSClientResolving
    ) {
        self.userClient = userClient
        self.credentials = credentials
        self.userSession = userSession
        self.e2eIdentityProvider = e2eIdentityProvider
        self.saveFileManager = saveFileManager
        self.logger = logger
        self.mlsClientResolver = mlsClientResolver
    }

    @MainActor
    func fetchCertificate() async -> E2eIdentityCertificate? {
        guard let mlsClientID = mlsClientResolver.mlsClientId(for: userClient),
              let data = mlsClientID.data(using: .utf8) else {
            return nil
        }
        do {
            return try await e2eIdentityProvider.fetchCertificates(clientIds: [data]).first
        } catch {
            logger.error(error.localizedDescription, attributes: nil)
            return nil
        }
    }

    @MainActor
    func isE2eIdentityEnabled() async -> Bool {
        do {
            return try await e2eIdentityProvider.isE2EIdentityEnabled()
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

    func shouldCertificateBeUpdated(certificate: E2eIdentityCertificate) -> Bool {
        e2eIdentityProvider.shouldCertificateBeUpdated(for: certificate)
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
