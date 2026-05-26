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

import WireData
import WireDataModel

public struct NewUserInfo: Equatable, Sendable {
    let userID: WireDataModel.QualifiedID
    let name: String
    let handle: String?
    let teamID: UUID?
    let type: WireDataModel.TypeOfUser?
    let accentID: Int
    let previewAssetKey: String?
    let completeAssetKey: String?
    let isDeleted: Bool
    let email: String?
    let expiresAt: Date?
    let appDescription: String?
    let appCategory: String?
    let serviceID: UUID?
    let serviceProvider: UUID?
    let supportedProtocols: Set<WireDataModel.MessageProtocol>?

    /// `true` only when the backend's `sso_id.subject` is non-empty (federated SSO,
    /// no Wire password). `false` when `sso_id` is missing or its `subject` is
    /// `nil`/blank — those users still authenticate with email + password and must
    /// be prompted for it. Only meaningful for the self user; defaults to `false`
    /// for other users.
    let usesCompanyLogin: Bool
}
