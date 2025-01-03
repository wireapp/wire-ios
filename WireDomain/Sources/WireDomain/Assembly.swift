//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPI
import WireDataModel
import WireFoundation

public final class Assembly {

    private let userID: UUID
    private let clientID: String
    private let context: NSManagedObjectContext
    private let sharedUserDefaults: UserDefaults
    private let proteusService: any ProteusServiceInterface
    private let apiService: any APIServiceProtocol
    private let apiVersion: WireAPI.APIVersion
    private let pushChannel: any PushChannelProtocol
    private let cookieStorage: ZMPersistentCookieStorage

    init(
        userID: UUID,
        clientID: String,
        context: NSManagedObjectContext,
        sharedUserDefaults: UserDefaults,
        proteusService: any ProteusServiceInterface,
        apiService: any APIServiceProtocol,
        apiVersion: WireAPI.APIVersion,
        pushChannel: any PushChannelProtocol,
        cookieStorage: ZMPersistentCookieStorage
    ) {
        self.userID = userID
        self.clientID = clientID
        self.context = context
        self.sharedUserDefaults = sharedUserDefaults
        self.proteusService = proteusService
        self.apiService = apiService
        self.apiVersion = apiVersion
        self.pushChannel = pushChannel
        self.cookieStorage = cookieStorage

        registerNotificationServiceDependencies()
    }

    // MARK: - API Init

    private lazy var updateEventsAPI = UpdateEventsAPIBuilder(
        apiService: apiService
    ).makeAPI(for: apiVersion)

    private lazy var updateEventDecryptor = UpdateEventDecryptor(
        proteusService: proteusService,
        context: context
    )

    // MARK: - Repositories and local stores Init

    private lazy var userLocalStore = UserLocalStore(context: context)

    private lazy var updateEventsLocalStore = UpdateEventsLocalStore(
        context: context,
        userID: userID,
        sharedUserDefaults: sharedUserDefaults
    )

}

extension Assembly {

    /// Register some domain dependencies to be resolved by the `NotificationService`.
    /// Since `NotificationService` is not initializable, the injector provides a lightweight dependency injection
    /// mechanism to retrieve some already initialized dependencies that the notification service requires.

    private func registerNotificationServiceDependencies() {
        Injector.register(UserLocalStoreProtocol.self) {
            self.userLocalStore
        }

        Injector.register(UpdateEventsAPI.self) {
            self.updateEventsAPI
        }

        Injector.register(PushChannelProtocol.self) {
            self.pushChannel
        }

        Injector.register(UpdateEventDecryptorProtocol.self) {
            self.updateEventDecryptor
        }

        Injector.register(UpdateEventsLocalStoreProtocol.self) {
            self.updateEventsLocalStore
        }

        Injector.register(ZMPersistentCookieStorage.self) {
            self.cookieStorage
        }
    }
}
