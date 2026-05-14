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

import Foundation

enum KMPStorageNamespace: Equatable, Hashable, Sendable {
    case shared
    case account(KMPAccountIdentity)
    case custom(String)
}

enum KMPStoragePurpose: Equatable, Hashable, Sendable {
    case applicationSupport
    case cache
    case temporary
}

struct KMPStoragePathRequest: Equatable, Hashable, Sendable {

    let namespace: KMPStorageNamespace
    let purpose: KMPStoragePurpose
    let component: String?

    init(
        namespace: KMPStorageNamespace,
        purpose: KMPStoragePurpose,
        component: String? = nil
    ) {
        self.namespace = namespace
        self.purpose = purpose
        self.component = component
    }
}

protocol KMPStoragePathProviding {
    func url(for request: KMPStoragePathRequest) throws -> URL
}

struct AnyKMPStoragePathProvider: KMPStoragePathProviding {

    private let resolveURL: (KMPStoragePathRequest) throws -> URL

    init<Provider: KMPStoragePathProviding>(_ provider: Provider) {
        self.resolveURL = { try provider.url(for: $0) }
    }

    init(resolveURL: @escaping (KMPStoragePathRequest) throws -> URL) {
        self.resolveURL = resolveURL
    }

    func url(for request: KMPStoragePathRequest) throws -> URL {
        try resolveURL(request)
    }
}
