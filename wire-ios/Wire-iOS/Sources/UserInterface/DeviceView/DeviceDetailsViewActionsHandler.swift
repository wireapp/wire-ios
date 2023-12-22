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

    var userClient: UserClient
    var clientRemovalObserver: ClientRemovalObserver?
    var credentials: ZMEmailCredentials?
    var certificate: E2eIdentityCertificate?
    var isProcessing: ((Bool) -> Void)?

    var isMLSEnabled: Bool {
        e2eIdentityProvider.isE2EIdentityEnabled()
    }

    var isE2eIdentityEnabled: Bool {
        e2eIdentityProvider.isE2EIdentityEnabled()
    }

    var shouldUpdateCertificate: Bool {
        guard let certificate = certificate else {
            return false
        }
        return e2eIdentityProvider.shouldUpdateCertificate(for: certificate)
    }
    var isSelfClient: Bool {
        userClient.isSelfClient()
    }

    init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?,
        e2eIdentityProvider: E2eIdentityProviding
    ) {
        self.userClient = userClient
        self.credentials = credentials
        self.userSession = userSession
        self.e2eIdentityProvider = e2eIdentityProvider
    }

    func fetchCertificate() async -> E2eIdentityCertificate? {
        do {
            return try await userClient.fetchE2eIdentityCertificates(e2eIdentityProvider: e2eIdentityProvider).first
        } catch {
            logger.error(error.localizedDescription)
        }
        return nil
    }

    func removeDevice() {
        clientRemovalObserver = ClientRemovalObserver(
            userClientToDelete: userClient,
            delegate: self,
            credentials: credentials,
            completion: {
                error in
                if let error = error {
                    WireLogger.e2ei.error(error.localizedDescription)
                }
            }
        )
        self.clientRemovalObserver?.startRemoval()
    }

    func resetSession() {
        userClient.resetSession()
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
        DispatchQueue.main.async {
            UIViewController.presentTopmost(viewController: viewControllerToPresent)
        }
    }

    func setIsLoadingViewVisible(
        _ clientRemovalObserver: ClientRemovalObserver,
        isVisible: Bool
    ) {
        DispatchQueue.main.async {
            self.isProcessing?(isVisible)
        }
    }
}
