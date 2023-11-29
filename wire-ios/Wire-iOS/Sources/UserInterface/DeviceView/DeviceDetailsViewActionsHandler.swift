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

    var userClient: UserClient
    var clientRemovalObserver: ClientRemovalObserver?
    var credentials: ZMEmailCredentials?
    var certificate: E2eIdentityCertificate?
    var isProcessing: ((Bool) -> Void)?
    let userSession: UserSession
    init(
        userClient: UserClient,
        userSession: UserSession,
        credentials: ZMEmailCredentials?
    ) {
        self.userClient = userClient
        self.credentials = credentials
        self.userSession = userSession
    }

    func fetchCertificate() async -> E2eIdentityCertificate? {
        do {
            return try await userClient.fetchE2eIdentityCertificate()
        } catch {
            print(
                error
            )
        }
        return nil
    }

    func showCertificate(
        _ certificate: String
    ) {
        print(
            "show certificate is called: \(certificate)"
        )
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
                    continuation.resume(
                        returning: isRemoved
                    )
                }
            )
            clientRemovalObserver?.startRemoval()
        }
    }

    func resetSession() async -> Bool {
        return await withCheckedContinuation { continuation in
            userClient.resetSession { value in
                continuation.resume(
                    returning: value
                )
            }
        }
    }

    func updateVerified(_ value: Bool) async -> Bool {
        return await withCheckedContinuation { continuation in
            userSession.enqueue({
                if value {
                    self.userClient.trustClient(self.userClient)
                } else {
                    self.userClient.ignoreClient(self.userClient)
                }
            },
                                completionHandler: {
                continuation.resume(
                    returning: value
                )
            })
        }
    }

    func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
    }
}

extension DeviceDetailsViewActionsHandler: ClientRemovalObserverDelegate {
    func present(
        _ clientRemovalObserver: ClientRemovalObserver,
        viewControllerToPresent: UIViewController
    ) {
        UIApplication.shared.windows.first?.rootViewController?.present(
            viewControllerToPresent,
            animated: true
        )
    }

    func setIsLoadingViewVisible(
        _ clientRemovalObserver: ClientRemovalObserver,
        isVisible: Bool
    ) {
        isProcessing?(isVisible)
    }
}
