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

import Foundation
import WireSyncEngine

final class ProfileDeviceDetailsViewModel: ObservableObject {
    @Published var deviceDetailsViewModel: DeviceInfoViewModel
    let isFromConversationView: Bool
    @Published var showDebugMenu = false
    @Published var showFingerPrint = false
    var showDebugButton: Bool = false

    init(deviceDetailsViewModel: DeviceInfoViewModel, isFromConversationView: Bool) {
        self.deviceDetailsViewModel = deviceDetailsViewModel
        self.isFromConversationView = isFromConversationView
    }

    func onShowMyDeviceTapped() {
        guard let session = ZMUserSession.shared(),
              let selfUserClient = session.selfUserClient else { return }

        let selfClientController = SettingsClientViewController(userClient: selfUserClient,
                                                                userSession: session,
                                                                fromConversation: isFromConversationView)

        let navigationControllerWrapper = selfClientController.wrapInNavigationController(setBackgroundColor: true)

        navigationControllerWrapper.modalPresentationStyle = .currentContext

    }

    func onDeleteDeviceTapped() {
        let clientObjectID = deviceDetailsViewModel.userClient.objectID
        guard let sync = deviceDetailsViewModel.userClient.managedObjectContext?.zm_sync else {
            return
        }
        Task {
            guard let client = try await sync.perform({ try sync.existingObject(with: clientObjectID) as? UserClient }) else {
                return
            }
            await client.deleteClientAndEndSession()
            _ = await sync.perform { sync.saveOrRollback() }
            await MainActor.run {

            }
        }
    }

    func onCorruptSessionTapped() {
        guard let sync = deviceDetailsViewModel.userClient.managedObjectContext?.zm_sync,
              let selfClientObjectID = ZMUser.selfUser()?.selfClient()?.objectID else {
            return
        }
        let userClientObjectID = deviceDetailsViewModel.userClient.objectID
        Task {
            do {
                guard let client = try await sync.perform({ try sync.existingObject(with: userClientObjectID) as? UserClient }),
                      let selfClient = try await sync.perform({ try sync.existingObject(with: selfClientObjectID) as? UserClient }) else {
                    return
                }
                _ = await selfClient.establishSessionWithClient(client, usingPreKey: "pQABAQACoQBYIBi1nXQxPf9hpIp1K1tBOj/tlBuERZHfTMOYEW38Ny7PA6EAoQBYIAZbZQ9KtsLVc9VpHkPjYy2+Bmz95fyR0MGKNUqtUUi1BPY=")
                _ = await sync.perform { sync.saveOrRollback() }
                await MainActor.run {

                }
            } catch {
                WireLogger.e2ei.debug(error.localizedDescription)
            }
        }
    }

    func onDuplicateClientTapped() {
        guard let context = deviceDetailsViewModel.userClient.managedObjectContext?.zm_sync else {
            return
        }
        context.performAndWait {
            guard
                let userID = deviceDetailsViewModel.userClient.user?.remoteIdentifier,
                let domain = deviceDetailsViewModel.userClient.user?.domain ?? BackendInfo.domain
            else {
                return
            }

            let user = ZMUser.fetch(
                with: userID,
                domain: domain,
                in: context
            )

            let duplicate = UserClient.insertNewObject(in: context)
            duplicate.remoteIdentifier = deviceDetailsViewModel.userClient.remoteIdentifier
            duplicate.user = user

            context.saveOrRollback()
        }
    }

    func onHowToDoThatTapped() {

    }
}
