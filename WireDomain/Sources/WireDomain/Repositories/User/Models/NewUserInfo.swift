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

import WireDataModel

public struct NewUserInfo: Equatable, Sendable {

    let userID: WireDataModel.QualifiedID
    let name: String
    let handle: String?
    let teamID: UUID?
    let accentID: Int
    let previewAssetKey: String?
    let completeAssetKey: String?
    let isDeleted: Bool
    let email: String?
    let expiresAt: Date?
    let serviceID: UUID?
    let serviceProvider: UUID?
    let supportedProtocols: Set<WireDataModel.MessageProtocol>?

    public init( // TODO: verify if this is alright
        userID: WireDataModel.QualifiedID,
        name: String,
        handle: String?,
        teamID: UUID?,
        accentID: Int,
        previewAssetKey: String?,
        completeAssetKey: String?,
        isDeleted: Bool,
        email: String?,
        expiresAt: Date?,
        serviceID: UUID?,
        serviceProvider: UUID?,
        supportedProtocols: Set<WireDataModel.MessageProtocol>?
    ) {
        self.userID = userID
        self.name = name
        self.handle = handle
        self.teamID = teamID
        self.accentID = accentID
        self.previewAssetKey = previewAssetKey
        self.completeAssetKey = completeAssetKey
        self.isDeleted = isDeleted
        self.email = email
        self.expiresAt = expiresAt
        self.serviceID = serviceID
        self.serviceProvider = serviceProvider
        self.supportedProtocols = supportedProtocols
    }

}
