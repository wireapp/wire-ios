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
import WireUtilities

public typealias KeyStorePerformBlock<T> = (UserClientKeysStore) throws -> T
public typealias ProteusServicePerformBlock<T> = (ProteusServiceInterface) throws -> T

public typealias KeyStorePerformAsyncBlock<T> = (UserClientKeysStore) async throws -> T
public typealias ProteusServicePerformAsyncBlock<T> = (ProteusServiceInterface) async throws -> T

// MARK: - ProteusProviding

public protocol ProteusProviding {
    func perform<T>(
        withProteusService proteusServiceBlock: ProteusServicePerformBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformBlock<T>
    ) rethrows -> T

    func performAsync<T>(
        withProteusService proteusServiceBlock: ProteusServicePerformAsyncBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformAsyncBlock<T>
    ) async rethrows -> T

    var canPerform: Bool { get }
}

// MARK: - ProteusProvider

public class ProteusProvider: ProteusProviding {
    // MARK: Lifecycle

    convenience init(
        context: NSManagedObjectContext,
        proteusViaCoreCrypto: Bool = DeveloperFlag.proteusViaCoreCrypto.isOn
    ) {
        self.init(
            proteusService: context.proteusService,
            keyStore: context.zm_cryptKeyStore,
            proteusViaCoreCrypto: proteusViaCoreCrypto
        )
    }

    public init(
        proteusService: ProteusServiceInterface?,
        keyStore: UserClientKeysStore?,
        proteusViaCoreCrypto: Bool = DeveloperFlag.proteusViaCoreCrypto.isOn
    ) {
        self.proteusService = proteusService
        self.keyStore = keyStore
        self.proteusViaCoreCrypto = proteusViaCoreCrypto
    }

    // MARK: Public

    public var canPerform: Bool {
        let canUseProteusService = proteusViaCoreCrypto && proteusService != nil
        let canUseKeyStore = !proteusViaCoreCrypto

        return canUseProteusService || canUseKeyStore
    }

    public func perform<T>(
        withProteusService proteusServiceBlock: ProteusServicePerformBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformBlock<T>
    ) rethrows -> T {
        if let proteusService, proteusViaCoreCrypto {
            return try proteusServiceBlock(proteusService)

        } else if let keyStore, !proteusViaCoreCrypto {
            // remove comment once implementation of proteus via core crypto is done
            return try keyStoreBlock(keyStore)
        } else {
            WireLogger.coreCrypto.error("can't access any proteus cryptography service")
            fatal("can't access any proteus cryptography service")
        }
    }

    public func performAsync<T>(
        withProteusService proteusServiceBlock: ProteusServicePerformAsyncBlock<T>,
        withKeyStore keyStoreBlock: KeyStorePerformAsyncBlock<T>
    ) async rethrows -> T {
        if let proteusService, proteusViaCoreCrypto {
            return try await proteusServiceBlock(proteusService)

        } else if let keyStore, !proteusViaCoreCrypto {
            // remove comment once implementation of proteus via core crypto is done
            return try await keyStoreBlock(keyStore)
        } else {
            WireLogger.coreCrypto.error("can't access any proteus cryptography service")
            fatal("can't access any proteus cryptography service")
        }
    }

    // MARK: Private

    private let proteusService: ProteusServiceInterface?
    private let keyStore: UserClientKeysStore?
    private let proteusViaCoreCrypto: Bool
}
