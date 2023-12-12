<<<<<<<< HEAD:wire-ios-request-strategy/Sources/Request Strategies/Conversation/MLSClientIDsProvider.swift
////
========
//
>>>>>>>> 860c0004f6da0a333a3e379e4cfb5385f34e3d15:wire-ios-data-model/Tests/Source/Model/Messages/ZMMessage+ServerTimestamp.swift
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

import Foundation
import WireDataModel

<<<<<<<< HEAD:wire-ios-request-strategy/Sources/Request Strategies/Conversation/MLSClientIDsProvider.swift
// sourcery: AutoMockable
protocol MLSClientIDsProviding {

    func fetchUserClients(
        for userID: QualifiedID,
        in context: NotificationContext
    ) async throws -> [MLSClientID]

}

struct MLSClientIDsProvider: MLSClientIDsProviding {

    func fetchUserClients(
        for userID: QualifiedID,
        in context: NotificationContext
    ) async throws -> [MLSClientID] {
        var action = FetchUserClientsAction(userIDs: [userID])
        let userClients = try await action.perform(in: context)
        return userClients.compactMap(MLSClientID.init(qualifiedClientID:))
========
extension ZMMessage {

    func updateServerTimestamp(with timeInterval: TimeInterval) {
        serverTimestamp = Date(timeIntervalSince1970: timeInterval)
>>>>>>>> 860c0004f6da0a333a3e379e4cfb5385f34e3d15:wire-ios-data-model/Tests/Source/Model/Messages/ZMMessage+ServerTimestamp.swift
    }

}
