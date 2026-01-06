// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name


import CoreLocation
import WireDataModel
import WireSyncEngine
import WireAccountImageUI
import WireMessagingDomain

@testable import Wire
@testable import WireCommonComponents

class MockGetUserByIdUseCaseProtocol: GetUserByIDUseCaseProtocol {

    // MARK: - getUserByID

    var getUserByIdIdContext_Invocations: [(id: Any, context: NSManagedObjectContext)] = []
    var getUserByIdIdContext_MockValue: (any UserType)?

    func getUserByID(id: Any, context: NSManagedObjectContext) -> (any UserType)? {
        getUserByIdIdContext_Invocations.append((id: id, context: context))

        if let mock = getUserByIdIdContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `getUserByIdIdContext`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
