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

public protocol IsFederationSearchAllowedUseCaseProtocol {

    /// It returns a bool value that indicates whether federated users can be added to the conversation.
    /// If the conversationProtocol parameter is nil, it indicates whether the selfUser can search for federated users.
    /// - Parameter conversationProtocol: conversationProtocol of the conversation where federated users can be added.
    /// - Returns: can self user communicate with federated users
    func invoke(conversationProtocol: MessageProtocol?) -> Bool
}

public struct IsFederationSearchAllowedUseCase: IsFederationSearchAllowedUseCaseProtocol {

    private let syncContext: NSManagedObjectContext
    private let defaultProtocol: Feature.MLS.Config.MessageProtocol

    public init(
        syncContext: NSManagedObjectContext,
        defaultProtocol: Feature.MLS.Config.MessageProtocol) {
            self.syncContext = syncContext
            self.defaultProtocol = defaultProtocol
        }

    public func invoke(conversationProtocol: MessageProtocol?) -> Bool {
        guard let conversationProtocol else {
            return defaultProtocol != .proteus
        }

        return conversationProtocol != .proteus
    }

}
