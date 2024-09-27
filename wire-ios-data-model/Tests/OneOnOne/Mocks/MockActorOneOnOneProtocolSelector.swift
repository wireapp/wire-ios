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
@testable import WireDataModel

actor MockActorOneOnOneProtocolSelector: OneOnOneProtocolSelectorInterface {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    // MARK: - getProtocolForUser

    var getProtocolForUserWithIn_Invocations: [(id: QualifiedID, context: NSManagedObjectContext)] = []
    var getProtocolForUserWithIn_MockMethod: ((QualifiedID, NSManagedObjectContext) async -> MessageProtocol?)?
    var getProtocolForUserWithIn_MockValue: MessageProtocol??

    func setGetProtocolForUserWithIn_MockMethod(_ method: @escaping (
        (QualifiedID, NSManagedObjectContext) async
            -> MessageProtocol?
    )) {
        getProtocolForUserWithIn_MockMethod = method
    }

    func setGetProtocolForUserWithIn_MockValue(_ messageProtocol: MessageProtocol??) {
        getProtocolForUserWithIn_MockValue = messageProtocol
    }

    func getProtocolForUser(with id: QualifiedID, in context: NSManagedObjectContext) async -> MessageProtocol? {
        getProtocolForUserWithIn_Invocations.append((id: id, context: context))

        if let mock = getProtocolForUserWithIn_MockMethod {
            return await mock(id, context)
        } else if let mock = getProtocolForUserWithIn_MockValue {
            return mock
        } else {
            fatalError("no mock for `getProtocolForUserWithIn`")
        }
    }
}
