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
import WireAPI
import WireDataModel

extension Collection<WireDataModel.QualifiedID> {

    func toAPIModel() -> [WireAPI.QualifiedID] {
        map { $0.toAPIModel() }
    }

}

extension WireDataModel.QualifiedID {

    func toAPIModel() -> WireAPI.QualifiedID {
        UserID(uuid: uuid, domain: domain)
    }

}

extension WireAPI.QualifiedID {

    func toDomainModel() -> WireDataModel.QualifiedID {
        WireDataModel.QualifiedID(uuid: uuid, domain: domain)
    }

}

extension Set<WireAPI.MessageProtocol> {

    func toDomainModel() -> Set<WireDataModel.MessageProtocol> {
        .init(map { $0.toDomainModel() })
    }

}

extension WireAPI.MessageProtocol {

    func toDomainModel() -> WireDataModel.MessageProtocol {
        switch self {
        case .mls: .mls
        case .proteus: .proteus
        }
    }
}

extension WireAPI.UserClientType {

    func toDomainModel() -> WireDataModel.DeviceType {
        switch self {
        case .permanent:
            .permanent
        case .temporary:
            .temporary
        case .legalhold:
            .legalHold
        }
    }

}

extension WireAPI.DeviceClass {
    func toDomainModel() -> WireDataModel.DeviceClass {
        switch self {
        case .phone:
            .phone
        case .tablet:
            .tablet
        case .desktop:
            .desktop
        case .legalhold:
            .legalHold
        }
    }
}

extension WireAPI.Prekey {

    func toDomainModel() -> WireDataModel.LegalHoldRequest.Prekey? {
        guard let data = Data(base64Encoded: base64EncodedKey) else {
            return nil
        }

        return .init(id: id, key: data)
    }

}
