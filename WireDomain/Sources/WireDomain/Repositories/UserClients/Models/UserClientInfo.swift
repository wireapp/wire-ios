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

import WireDataModel
import WireNetwork

public struct UserClientInfo: Sendable {

    let id: String
    let label: String?
    let type: WireDataModel.DeviceType
    let activationDate: Date?
    let model: String?
    let deviceClass: WireDataModel.DeviceClass?
    let lastActiveDate: Date?
    let mlsPublicKeys: UserClientInfo.MLSPublicKeys?
    let capabilities: [UserClientCapability]

    struct MLSPublicKeys {
        let ed25519: String?
        let ed448: String?
        let p256: String?
        let p384: String?
        let p521: String?
    }
}
