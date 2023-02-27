//
//  MockProteusProvider.swift
//  WireDataModelTests
//
//  Created by F on 27/02/2023.
//  Copyright © 2023 Wire Swiss GmbH. All rights reserved.
//

import Foundation
import WireDataModel

class MockProteusProvider: ProteusProviding {

    let mockProteusService: MockProteusServiceInterface
    let mockKeyStore: SpyUserClientKeyStore
    var useProteusService: Bool

    init(
        mockProteusService: MockProteusServiceInterface,
        mockKeyStore: SpyUserClientKeyStore,
        useProteusService: Bool = false
    ) {
        self.mockProteusService = mockProteusService
        self.mockKeyStore = mockKeyStore
        self.useProteusService = useProteusService
    }

    func perform<T>(
        withProteusService proteusServiceBlock: (ProteusServiceInterface) throws -> T,
        withKeyStore keyStoreBlock: (UserClientKeysStore) throws -> T)
    rethrows -> T {
        if useProteusService {
            return try proteusServiceBlock(mockProteusService)
        } else {
            return try keyStoreBlock(mockKeyStore)
        }
    }
}
