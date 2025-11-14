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

import WireNetwork

extension WireNetwork.SelfUserClient {

    func toDomainModel() -> UserClientInfo {
        .init(
            id: id,
            label: label,
            type: type.toDomainModel(),
            activationDate: activationDate,
            model: model,
            deviceClass: deviceClass?.toDomainModel(),
            lastActiveDate: lastActiveDate,
            mlsPublicKeys: .init(
                ed25519: mlsPublicKeys?.ed25519,
                ed448: mlsPublicKeys?.ed448,
                p256: mlsPublicKeys?.p256,
                p384: mlsPublicKeys?.p384,
                p521: mlsPublicKeys?.p521
            ), capabilities: capabilities
        )
    }

}
