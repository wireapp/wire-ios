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

import CoreData
import WireDataModel

public class MockGetTeamAccountImageSourceUseCaseProtocol: GetTeamAccountImageSourceUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - invoke

    public var invokeUserUserContextAccount_Invocations: [(user: any UserType, userContext: NSManagedObjectContext?, account: Account)] = []
    public var invokeUserUserContextAccount_MockError: Error?
    public var invokeUserUserContextAccount_MockMethod: ((any UserType, NSManagedObjectContext?, Account) async throws -> AccountImageSource)?
    public var invokeUserUserContextAccount_MockValue: AccountImageSource?

    public func invoke(user: some UserType, userContext: NSManagedObjectContext?, account: Account) async throws -> AccountImageSource {
        invokeUserUserContextAccount_Invocations.append((user: user, userContext: userContext, account: account))

        if let error = invokeUserUserContextAccount_MockError {
            throw error
        }

        if let mock = invokeUserUserContextAccount_MockMethod {
            return try await mock(user, userContext, account)
        } else if let mock = invokeUserUserContextAccount_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUserUserContextAccount`")
        }
    }
}

public class MockGetUserAccountImageSourceUseCaseProtocol: GetUserAccountImageSourceUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - invoke

    public var invokeUserUserContextAccount_Invocations: [(user: any UserType, userContext: NSManagedObjectContext?, account: Account)] = []
    public var invokeUserUserContextAccount_MockError: Error?
    public var invokeUserUserContextAccount_MockMethod: ((any UserType, NSManagedObjectContext?, Account) async throws -> AccountImageSource)?
    public var invokeUserUserContextAccount_MockValue: AccountImageSource?

    public func invoke(user: some UserType, userContext: NSManagedObjectContext?, account: Account) async throws -> AccountImageSource {
        invokeUserUserContextAccount_Invocations.append((user: user, userContext: userContext, account: account))

        if let error = invokeUserUserContextAccount_MockError {
            throw error
        }

        if let mock = invokeUserUserContextAccount_MockMethod {
            return try await mock(user, userContext, account)
        } else if let mock = invokeUserUserContextAccount_MockValue {
            return mock
        } else {
            fatalError("no mock for `invokeUserUserContextAccount`")
        }
    }

}
