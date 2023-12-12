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
    let logger = WireLogger.e2ei
    let e2eIdentityProvider: E2eIdentityProviding
    let userSession: UserSession
    let mlsProvider: MLSProviding

    var userClient: UserClient
    var clientRemovalObserver: ClientRemovalObserver?
    var credentials: ZMEmailCredentials?
    var certificate: E2eIdentityCertificate?
    var isProcessing: ((Bool) -> Void)?

    var isMLSEnabled: Bool {
        mlsProvider.isMLSEnbaled
    }

    var isE2eIdentityEnabled: Bool {
        e2eIdentityProvider.isE2EIdentityEnabled
    }

    var isSelfClient: Bool {
        userClient.isSelfClient()
    }

    init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        e2eIdentityProvider: E2eIdentityProviding,
        mlsProvider: MLSProviding
    ) {
        self.userClient = userClient
        self.credentials = credentials
        self.userSession = userSession
        self.e2eIdentityProvider = e2eIdentityProvider
        self.mlsProvider = mlsProvider
    }

    func fetchCertificate() async -> E2eIdentityCertificate? {
        do {
            return try await userClient.fetchE2eIdentityCertificate(e2eIdentityProvider: e2eIdentityProvider)
        } catch {
            logger.error(error.localizedDescription)
        }
        return nil
    }

    func fetchMLSThumbprint() async -> String? {
        do {
            return try await mlsProvider.fetchMLSThumbprint()
        } catch {
            logger.error(error.localizedDescription)
        }
        return nil
    }

    func removeDevice() async -> Bool {
        isProcessing?(true)
        return await withCheckedContinuation {[weak self] continuation in
            guard let self = self else {
                return
            }
            clientRemovalObserver = ClientRemovalObserver(
                userClientToDelete: userClient,
                delegate: self,
                credentials: credentials,
                completion: {
                    error in
                    let isRemoved = error == nil
                    continuation.resume(returning: isRemoved)
                }
            )
            clientRemovalObserver?.startRemoval()
        }
    }

    func resetSession() async -> Bool {
        return await withCheckedContinuation { continuation in
            userClient.resetSession { value in
                continuation.resume(returning: value)
            }
        }
    }

    func updateVerified(_ isVerified: Bool) async -> Bool {
        return await withCheckedContinuation { continuation in
            userSession.enqueue({
                    if isVerified {
                        self.userClient.trustClient(self.userClient)
                    } else {
                        self.userClient.ignoreClient(self.userClient)
                    }
                }, completionHandler: {
                    continuation.resume(returning: isVerified)
                }
            )
        }
    }

    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
    }

    func downloadE2EIdentityCertificate() {
        guard let certificate = certificate else {
            return
        }
        let fileName = "e2eiCertifcate.txt"
        let path = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try certificate.certificateDetails.write(
                to: path,
                atomically: true,
                encoding: String.Encoding.utf8
            )
        } catch {
            logger.error(error.localizedDescription)
        }
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )
        return paths[0]
    }
}

extension DeviceDetailsViewActionsHandler: ClientRemovalObserverDelegate {
    func present(
        _ clientRemovalObserver: ClientRemovalObserver,
        viewControllerToPresent: UIViewController
    ) {
        UIViewController.presentTopmost(viewController: viewControllerToPresent)
    }

    func setIsLoadingViewVisible(
        _ clientRemovalObserver: ClientRemovalObserver,
        isVisible: Bool
    ) {
        isProcessing?(isVisible)
    }
}
