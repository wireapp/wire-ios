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

public import WireFoundation

public actor KeychainProtocolMock: KeychainProtocol {

    // MARK: - Init

    public init() {}

    // MARK: - addItem

    public var addItemQuery_Invocations: [Set<KeychainQueryItem>] = []

    var addItemQuery_MockError: (any Error)?
    public func setAddItemQuery_MockError(_ error: any Error) {
        addItemQuery_MockError = error
    }

    var addItemQuery_MockMethod: ((Set<KeychainQueryItem>) async throws -> Void)?
    public func setAddItemQuery_MockMethod(_ method: @escaping (Set<KeychainQueryItem>) async throws -> Void) {
        addItemQuery_MockMethod = method
    }

    public func addItem(query: Set<KeychainQueryItem>) async throws {
        addItemQuery_Invocations.append(query)

        if let error = addItemQuery_MockError {
            throw error
        }

        guard let mock = addItemQuery_MockMethod else {
            fatalError("no mock for `addItemQuery`")
        }

        try await mock(query)
    }

    // MARK: - updateItem

    public var updateItemQueryAttributesToUpdate_Invocations: [(query: Set<KeychainQueryItem>, attributesToUpdate: Set<KeychainQueryItem>)] = []

    var updateItemQueryAttributesToUpdate_MockError: (any Error)?
    public func setUpdateItemQueryAttributesToUpdate_MockError(_ error: any Error) {
        updateItemQueryAttributesToUpdate_MockError = error
    }

    var updateItemQueryAttributesToUpdate_MockMethod: ((Set<KeychainQueryItem>, Set<KeychainQueryItem>) async throws -> Void)?
    public func setUpdateItemQueryAttributesToUpdate_MockMethod(_ method: @escaping (Set<KeychainQueryItem>, Set<KeychainQueryItem>) async throws -> Void) {
        updateItemQueryAttributesToUpdate_MockMethod = method
    }

    public func updateItem(query: Set<KeychainQueryItem>, attributesToUpdate: Set<KeychainQueryItem>) async throws {
        updateItemQueryAttributesToUpdate_Invocations.append((query: query, attributesToUpdate: attributesToUpdate))

        if let error = updateItemQueryAttributesToUpdate_MockError {
            throw error
        }

        guard let mock = updateItemQueryAttributesToUpdate_MockMethod else {
            fatalError("no mock for `updateItemQueryAttributesToUpdate`")
        }

        try await mock(query, attributesToUpdate)
    }

    // MARK: - fetchItem<T>

    public var fetchItemQuery_Invocations: [Set<KeychainQueryItem>] = []

    var fetchItemQuery_MockError: (any Error)?
    public func setFetchItemQuery_MockError(_ error: any Error) {
        fetchItemQuery_MockError = error
    }

    var fetchItemQuery_MockMethod: ((Set<KeychainQueryItem>) async throws -> (any Sendable)?)?
    public func setFetchItemQuery_MockMethod(
        _ method: @escaping (Set<KeychainQueryItem>) async throws -> (any Sendable)?
    ) {
        fetchItemQuery_MockMethod = method
    }

    var fetchItemQuery_MockValue: (any Sendable)??
    public func setFetchItemQuery_MockValue(_ value: (any Sendable)?) async {
        fetchItemQuery_MockValue = value
    }

    public func fetchItem<T: Sendable>(query: Set<KeychainQueryItem>) async throws -> T? {
        fetchItemQuery_Invocations.append(query)

        if let error = fetchItemQuery_MockError {
            throw error
        }

        if let mock = fetchItemQuery_MockMethod {
            return try await mock(query) as? T
        } else if let mock = fetchItemQuery_MockValue {
            return mock as? T
        } else {
            fatalError("no mock for `fetchItemQuery`")
        }
    }

    // MARK: - deleteItem

    public var deleteItemQuery_Invocations: [Set<KeychainQueryItem>] = []

    var deleteItemQuery_MockError: (any Error)?
    public func setDeleteItemQuery_MockError(_ error: any Error) {
        deleteItemQuery_MockError = error
    }

    var deleteItemQuery_MockMethod: ((Set<KeychainQueryItem>) async throws -> Void)?
    public func setDeleteItemQuery_MockMethod(_ method: @escaping (Set<KeychainQueryItem>) async throws -> Void) {
        deleteItemQuery_MockMethod = method
    }

    public func deleteItem(query: Set<KeychainQueryItem>) async throws {
        deleteItemQuery_Invocations.append(query)

        if let error = deleteItemQuery_MockError {
            throw error
        }

        guard let mock = deleteItemQuery_MockMethod else {
            fatalError("no mock for `deleteItemQuery`")
        }

        try await mock(query)
    }

}
