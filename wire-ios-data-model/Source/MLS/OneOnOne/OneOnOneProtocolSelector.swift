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

import Foundation

// sourcery: AutoMockable
public protocol OneOnOneProtocolSelectorInterface {

    func getProtocolInsersectionBetween(
        selfUser: ZMUser,
        otherUser: ZMUser,
        in context: NSManagedObjectContext
    ) async -> MessageProtocol?
}

public struct OneOnOneProtocolSelector: OneOnOneProtocolSelectorInterface {

    public init() {}

    public func getProtocolInsersectionBetween(
        selfUser: ZMUser,
        otherUser: ZMUser,
        in context: NSManagedObjectContext
    ) async -> MessageProtocol? {

        let commonProtocols = await context.perform {
            let selfProtocols = selfUser.supportedProtocols
            let otherProtocols = otherUser.supportedProtocols

            return selfProtocols.intersection(otherProtocols)
        }

        if commonProtocols.contains(.mls) {
            return .mls
        } else if commonProtocols.contains(.proteus) {
            return .proteus
        } else {
            return nil
        }
    }
}
