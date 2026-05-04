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
import WireNetwork

struct StorableUserUpdateEvent: Equatable, Codable, Sendable {

    private let userID: UUID
    private let accentColorID: Int?
    private let name: String?
    private let handle: String?
    private let email: String?
    private let isSSOIDDeleted: Bool?
    private let assets: [StorableUserAsset]?
    private let supportedProtocols: [StorableMessageProtocol]?

    init(_ value: WireNetwork.UserUpdateEvent) {
        self.userID = value.userID
        self.accentColorID = value.accentColorID
        self.name = value.name
        self.handle = value.handle
        self.email = value.email
        self.isSSOIDDeleted = value.isSSOIDDeleted
        self.assets = value.assets?.map {
            StorableUserAsset(key: $0.key, size: StorableUserAssetSize($0.size), type: StorableUserAssetType($0.type))
        }
        self.supportedProtocols = value.supportedProtocols?.map { StorableMessageProtocol($0) }
    }

    func toAPIModel() -> WireNetwork.UserUpdateEvent {
        .init(
            userID: userID,
            accentColorID: accentColorID,
            name: name,
            handle: handle,
            email: email,
            isSSOIDDeleted: isSSOIDDeleted,
            assets: assets?.map {
                WireNetwork.UserAsset(key: $0.key, size: $0.size.toAPIModel(), type: $0.type.toAPIModel())
            },
            supportedProtocols: supportedProtocols?.map { $0.toAPIModel() }.toSet()
        )
    }

}

private enum StorableUserAssetSize: String, Codable, Equatable, Sendable {

    case preview
    case complete

    init(_ value: WireNetwork.UserAssetSize) {
        switch value {
        case .preview:
            self = .preview
        case .complete:
            self = .complete
        }
    }

    func toAPIModel() -> WireNetwork.UserAssetSize {
        switch self {
        case .preview:
            .preview
        case .complete:
            .complete
        }
    }

}

private enum StorableUserAssetType: String, Codable, Equatable, Sendable {

    case image

    init(_ value: WireNetwork.UserAssetType) {
        switch value {
        case .image:
            self = .image
        }
    }

    func toAPIModel() -> WireNetwork.UserAssetType {
        switch self {
        case .image:
            .image
        }
    }

}

private struct StorableUserAsset: Codable, Equatable, Sendable {

    let key: String
    let size: StorableUserAssetSize
    let type: StorableUserAssetType

}
