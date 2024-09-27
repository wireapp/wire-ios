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
import WireDataModel

public class MockProteusProvider: ProteusProviding {
    // MARK: Lifecycle

    public init(
        mockProteusService: MockProteusServiceInterface = MockProteusServiceInterface(),
        mockKeyStore: SpyUserClientKeyStore = MockProteusProvider.spyForTests(),
        useProteusService: Bool = false
    ) {
        self.mockProteusService = mockProteusService
        self.mockKeyStore = mockKeyStore
        self.useProteusService = useProteusService
    }

    // MARK: Public

    public let mockProteusService: MockProteusServiceInterface
    public let mockKeyStore: SpyUserClientKeyStore
    public var useProteusService: Bool

    public var mockCanPerform = true

    public var canPerform: Bool {
        mockCanPerform
    }

    public static func spyForTests() -> SpyUserClientKeyStore {
        let url = Self.createTempFolder()
        return SpyUserClientKeyStore(accountDirectory: url, applicationContainer: url)
    }

    // FIXME: [WPB-5867] this is defined in WireTesting, somehow it is not possible to import here for now - [Francois]
    public static func createTempFolder() -> URL {
        let url = URL(fileURLWithPath: [NSTemporaryDirectory(), UUID().uuidString].joined(separator: "/"))
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return url
    }

    public func perform<T>(
        withProteusService proteusServiceBlock: (ProteusServiceInterface) throws -> T,
        withKeyStore keyStoreBlock: (UserClientKeysStore) throws -> T
    )
        rethrows -> T {
        if useProteusService {
            try proteusServiceBlock(mockProteusService)
        } else {
            try keyStoreBlock(mockKeyStore)
        }
    }

    public func performAsync<T>(
        withProteusService proteusServiceBlock: (ProteusServiceInterface) async throws -> T,
        withKeyStore keyStoreBlock: (UserClientKeysStore) async throws -> T
    )
        async rethrows -> T {
        if useProteusService {
            try await proteusServiceBlock(mockProteusService)
        } else {
            try await keyStoreBlock(mockKeyStore)
        }
    }
}
