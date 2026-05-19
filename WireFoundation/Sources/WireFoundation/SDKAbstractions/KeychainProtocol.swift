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

public import Foundation

/// A protocol mirroring Keychain api to allow mocking in tests.
public protocol KeychainProtocol: Sendable {

    func addItem(
        query: Set<KeychainQueryItem>
    ) throws

    func updateItem(
        query: Set<KeychainQueryItem>,
        attributesToUpdate: Set<KeychainQueryItem>
    ) throws

    func fetchItem<T>(
        query: Set<KeychainQueryItem>
    ) throws -> T?

    func deleteItem(
        query: Set<KeychainQueryItem>
    ) throws

}

public enum KeychainError: Error {

    case failedToCastResult
    case errorStatus(OSStatus)

}

public enum KeychainQueryItem: Hashable, Equatable, Sendable {

    case service(String)
    case account(String)
    case generic(Data)
    case itemClass(ItemClass)
    case accessible(ItemAccessibility)
    case returningData(Bool)
    case data(Data)
    case returningAttributes(Bool)

    public enum ItemClass: Equatable, Sendable {

        case genericPassword
        case internetPassword
        case certificate
        case key
        case identity

    }

    public enum ItemAccessibility: Equatable, Sendable {

        case afterFirstUnlock

    }

    func toCFDictionaryEntry() -> (CFString, Any) {
        switch self {
        case let .service(string):
            (kSecAttrService, string)

        case let .account(string):
            (kSecAttrAccount, string)

        case let .generic(data):
            (kSecAttrGeneric, data)

        case .itemClass(.genericPassword):
            (kSecClass, kSecClassGenericPassword)

        case .itemClass(.internetPassword):
            (kSecClass, kSecClassInternetPassword)

        case .itemClass(.certificate):
            (kSecClass, kSecClassCertificate)

        case .itemClass(.key):
            (kSecClass, kSecClassKey)

        case .itemClass(.identity):
            (kSecClass, kSecClassIdentity)

        case .accessible(.afterFirstUnlock):
            (kSecAttrAccessible, kSecAttrAccessibleAfterFirstUnlock)

        case let .returningData(bool):
            (kSecReturnData, bool)

        case let .data(data):
            (kSecValueData, data)

        case let .returningAttributes(bool):
            (kSecReturnAttributes, bool)
        }
    }

}
