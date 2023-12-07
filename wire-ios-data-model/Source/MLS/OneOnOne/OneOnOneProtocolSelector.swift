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

public protocol OneOnOneProtocolSelectorInterface {

    func getProtocolForUser(
        with id: QualifiedID,
        in context: NSManagedObjectContext
    ) -> MessageProtocol?

}

public final class OneOnOneProtocolSelector: OneOnOneProtocolSelectorInterface {

    public init() {
        
    }

    public func getProtocolForUser(
        with id: QualifiedID,
        in context: NSManagedObjectContext
    ) -> MessageProtocol? {
        let selfUser = ZMUser.selfUser(in: context)
        let otherUser = ZMUser.fetch(with: id, in: context)

        let selfProtocols = selfUser.supportedProtocols
        let otherProtocols = otherUser?.supportedProtocols ?? []
        let commonProtocols = selfProtocols.intersection(otherProtocols)

        if commonProtocols.contains(.mls) {
            return .mls
        } else if commonProtocols.contains(.proteus) {
            return .proteus
        } else {
            return nil
        }
    }

}
