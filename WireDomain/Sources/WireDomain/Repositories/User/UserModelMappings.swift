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

import Foundation
import WireDataModel
import WireNetwork

extension Collection<WireDataModel.QualifiedID> {

    func toAPIModel() -> [WireNetwork.QualifiedID] {
        map { $0.toAPIModel() }
    }

}

extension WireDataModel.QualifiedID {

    func toAPIModel() -> WireNetwork.QualifiedID {
        UserID(id: uuid, domain: domain)
    }

}

extension WireNetwork.QualifiedID {

    func toDomainModel() -> WireDataModel.QualifiedID {
        WireDataModel.QualifiedID(uuid: id, domain: domain)
    }

}

extension Set<WireNetwork.MessageProtocol> {

    func toDomainModel() -> Set<WireDataModel.MessageProtocol> {
        .init(map { $0.toDomainModel() })
    }

}

extension WireNetwork.MessageProtocol {

    func toDomainModel() -> WireDataModel.MessageProtocol {
        switch self {
        case .mls: .mls
        case .proteus: .proteus
        }
    }
}

extension WireNetwork.UserType {

    func toDomainModel() -> WireDataModel.TypeOfUser {
        switch self {
        case .regular:
            .regular
        case .app:
            .app
        case .bot:
            .bot
        }
    }

}

extension WireNetwork.UserClientType {

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

extension WireNetwork.DeviceClass {
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

extension WireNetwork.Prekey {

    func toDomainModel() -> WireDataModel.LegalHoldRequest.Prekey? {
        guard let data = Data(base64Encoded: base64EncodedKey) else {
            return nil
        }

        return .init(id: id, key: data)
    }

}

extension WireNetwork.UserUpdateEvent {

    func toDomainModel() -> UserUpdateInfo {
        .init(
            userID: userID,
            accentColorID: accentColorID,
            name: name,
            handle: handle,
            email: email,
            isSSOIDDeleted: isSSOIDDeleted,
            previewAssetKey: assets?
                .first(where: { $0.size == .preview })
                .map(\.key),
            completeAssetKey: assets?
                .first(where: { $0.size == .complete })
                .map(\.key),
            supportedProtocols: supportedProtocols?.toDomainModel()
        )
    }

}

extension WireNetwork.User {

    func toDomainModel() -> NewUserInfo {

        .init(
            userID: id.toDomainModel(),
            name: name,
            handle: handle,
            teamID: teamID,
            type: type?.toDomainModel(),
            accentID: accentID,
            previewAssetKey: assets
                .first(where: { $0.size == .preview })
                .map(\.key),
            completeAssetKey: assets
                .first(where: { $0.size == .complete })
                .map(\.key),
            isDeleted: deleted ?? false,
            email: email,
            expiresAt: expiresAt,
            serviceID: service?.id,
            serviceProvider: service?.provider,
            supportedProtocols: supportedProtocols?.toDomainModel()
        )

    }

}

extension WireNetwork.SelfUser {

    func toDomainModel() -> NewUserInfo {
        .init(
            userID: qualifiedID.toDomainModel(),
            name: name,
            handle: handle,
            teamID: teamID,
            type: .regular,
            accentID: accentID,
            previewAssetKey: assets?
                .first(where: { $0.size == .preview })
                .map(\.key),
            completeAssetKey: assets?
                .first(where: { $0.size == .complete })
                .map(\.key),
            isDeleted: deleted ?? false,
            email: email,
            expiresAt: expiresAt,
            serviceID: service?.id,
            serviceProvider: service?.provider,
            supportedProtocols: supportedProtocols?.toDomainModel()
        )
    }

}
