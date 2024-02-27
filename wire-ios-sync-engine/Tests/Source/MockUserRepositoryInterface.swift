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

import XCTest
@testable import WireSyncEngine

public class MockUserRepositoryInterface: UserRepositoryInterface {

    // MARK: - Life cycle

    public init() {}

    // MARK: - selfUser

    public var selfUser_Invocations: [Void] = []
    public var selfUser_MockMethod: (() -> ZMUser)?
    public var selfUser_MockValue: ZMUser?

    public func selfUser() -> ZMUser {
        selfUser_Invocations.append(())

        if let mock = selfUser_MockMethod {
            return mock()
        } else if let mock = selfUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `selfUser`")
        }
    }

}
