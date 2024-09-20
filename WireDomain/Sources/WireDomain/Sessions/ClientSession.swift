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

import CoreData
import Foundation
import WireAPI
import WireDataModel

public struct ClientSession {

    private let clientID: String
    private let updateEventsAPI: any UpdateEventsAPI
    private let updateEventsRepository: UpdateEventsRepository
    private let syncManager: SyncManager
    private let apiService: APIService

    public init(
        clientID: String,
        backendURL: URL,
        authenticationStorage: any AuthenticationStorage,
        proteusService: any ProteusServiceInterface,
        syncContext: NSManagedObjectContext,
        eventContext: NSManagedObjectContext,
        lastEventIDRepository: any LastEventIDRepositoryInterface
    ) {
        self.clientID = clientID

        apiService = APIService(
            clientID: clientID,
            backendURL: backendURL,
            authenticationStorage: authenticationStorage,
            minTLSVersion: .v1_2
        )

        updateEventsAPI = UpdateEventsAPIBuilder(apiService: apiService).makeAPI(for: .v5)

        let updateEventDecryptor = UpdateEventDecryptor(
            proteusService: proteusService,
            context: syncContext
        )

        updateEventsRepository = UpdateEventsRepository(
            selfClientID: clientID,
            updateEventsAPI: updateEventsAPI,
            pushChannel: DebugPushChannel(),
            updateEventDecryptor: updateEventDecryptor,
            eventContext: eventContext,
            lastEventIDRepository: lastEventIDRepository
        )

        syncManager = SyncManager(
            updateEventsRepository: updateEventsRepository,
            updateEventProcessor: DebugUpdateEventProcessor()
        )
    }

    public func doSomething() async {
        do {
            print("[DEBUG] fetching event")
            let envelope = try await updateEventsAPI.getLastUpdateEvent(selfClientID: clientID)
            print("[DEBUG] fetched event: \(envelope)")
        } catch {
            print("[DEBUG] failed to fetched event: \(error)")
        }
    }

}

private struct DebugUpdateEventProcessor: UpdateEventProcessorProtocol {
    
    func processEvent(_ event: WireAPI.UpdateEvent) async throws {
        print("processing event: \(event)")
    }

}

private struct DebugPushChannel: PushChannelProtocol {

    func open() throws -> AsyncThrowingStream<WireAPI.UpdateEventEnvelope, any Error> {
        fatalError("not implemented yet")
    }
    
    func close() {
        fatalError("not implemented yet")
    }

}
