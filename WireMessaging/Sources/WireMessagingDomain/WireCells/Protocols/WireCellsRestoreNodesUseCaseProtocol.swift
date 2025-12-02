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

<<<<<<<< HEAD:wire-ios/Wire-iOS/Sources/UserInterface/MainController/DefaultManagedObjectContextProvider.swift
import WireData
import WireDataModel

struct DefaultManagedObjectContextProvider: ManagedObjectContextProvider {

    let contextProvider: any ContextProvider

    var viewContext: NSManagedObjectContext {
        contextProvider.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        contextProvider.newBackgroundContext()
    }
========
public import Foundation

public protocol WireCellsRestoreNodesUseCaseProtocol: Sendable {

    func invoke(nodeIDs: [UUID]) async throws
>>>>>>>> feat/hint-banner-for-disabled-apps-WPB-21441-cherry-pick:WireMessaging/Sources/WireMessagingDomain/WireCells/Protocols/WireCellsRestoreNodesUseCaseProtocol.swift

}
