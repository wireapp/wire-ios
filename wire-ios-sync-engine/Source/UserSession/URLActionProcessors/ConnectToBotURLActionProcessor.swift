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

final class ConnectToBotURLActionProcessor: NSObject, URLActionProcessor {

    var transportSession: TransportSessionType
    var eventProcessor: ConversationEventProcessorProtocol
    var contextProvider: ContextProvider
    var searchUsersCache: SearchUsersCache?

    init(
        contextprovider: ContextProvider,
        transportSession: TransportSessionType,
        eventProcessor: ConversationEventProcessorProtocol,
        searchUsersCache: SearchUsersCache?
    ) {
        self.contextProvider = contextprovider
        self.transportSession = transportSession
        self.eventProcessor = eventProcessor
    }

    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        guard case .connectBot(let serviceUserData) = urlAction else { return }

        let serviceUser = ZMSearchUser(
            contextProvider: contextProvider,
            name: "",
            handle: nil,
            accentColor: .blue,
            remoteIdentifier: serviceUserData.service,
            teamIdentifier: nil,
            user: nil,
            contact: nil,
            searchUsersCache: searchUsersCache
        )
        serviceUser.providerIdentifier = serviceUserData.provider.transportString()
        serviceUser.createConversation(
            transportSession: transportSession,
            eventProcessor: eventProcessor,
            contextProvider: contextProvider
        ) { [weak delegate] result in
            switch result {
            case .success:
                delegate?.completedURLAction(urlAction)
            case .failure(let error):
                delegate?.failedToPerformAction(urlAction, error: error)
            }
        }
    }
}
