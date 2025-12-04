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

import Foundation

final class ConnectToBotURLActionProcessor: NSObject, URLActionProcessor {

    var transportSession: TransportSessionType
    var eventProcessor: LegacyConversationEventProcessorProtocol
    var contextProvider: ContextProvider
    var searchUsersCache: SearchUsersCache?
    let metadata: BackendMetadataProvider

    init(
        contextprovider: ContextProvider,
        transportSession: TransportSessionType,
        eventProcessor: LegacyConversationEventProcessorProtocol,
        searchUsersCache: SearchUsersCache?,
        metadata: BackendMetadataProvider
    ) {
        self.contextProvider = contextprovider
        self.transportSession = transportSession
        self.eventProcessor = eventProcessor
        self.metadata = metadata
    }

    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        guard case let .connectBot(serviceUserData) = urlAction else { return }

        let providerIdentifier = serviceUserData.provider.transportString()
        let serviceUser = ZMSearchUser(
            contextProvider: contextProvider,
            name: "",
            handle: nil,
            accentColor: .blue,
            remoteIdentifier: serviceUserData.service,
            teamIdentifier: nil,
            user: nil,
            searchUsersCache: searchUsersCache
        )
        serviceUser.providerIdentifier = providerIdentifier
        serviceUser.createConversation(
            transportSession: transportSession,
            eventProcessor: eventProcessor,
            contextProvider: contextProvider,
            metadata: metadata
        ) { [weak delegate] result in
            switch result {
            case .success:
                delegate?.completedURLAction(urlAction)
            case let .failure(error):
                delegate?.failedToPerformAction(urlAction, error: error)
            }
        }
    }
}
