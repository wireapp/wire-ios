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
import WireAPI

struct StorableUserClientAddEvent: Equatable, Codable, Sendable {

    private let client: StorableSelfUserClient

    init(_ value: WireAPI.UserClientAddEvent) {
        self.client = StorableSelfUserClient(
            id: value.client.id,
            type: StorableUserClientType(value.client.type),
            activationDate: value.client.activationDate,
            label: value.client.label,
            model: value.client.model,
            deviceClass: value.client.deviceClass.map(StorableDeviceClass.init),
            lastActiveDate: value.client.lastActiveDate,
            mlsPublicKeys: value.client.mlsPublicKeys.map {
                StorableMLSPublicKeys(
                    ed25519: $0.ed25519,
                    ed448: $0.ed448,
                    p256: $0.p256,
                    p384: $0.p384,
                    p512: $0.p512
                )
            },
            cookie: value.client.cookie,
            capabilities: value.client.capabilities.map(StorableUserClientCapability.init)
        )
    }

    func toAPIModel() -> WireAPI.UserClientAddEvent {
        .init(
            client: .init(
                id: client.id,
                type: client.type.toAPIModel(),
                activationDate: client.activationDate,
                label: client.label,
                model: client.model,
                deviceClass: client.deviceClass?.toAPIModel(),
                lastActiveDate: client.lastActiveDate,
                mlsPublicKeys: client.mlsPublicKeys.map {
                    WireAPI.MLSPublicKeys(
                        ed25519: $0.ed25519,
                        ed448: $0.ed448,
                        p256: $0.p256,
                        p384: $0.p384,
                        p512: $0.p512
                    )
                },
                cookie: client.cookie,
                capabilities: client.capabilities.map { $0.toAPIModel() }
            )
        )
    }

}

// MARK: - Private models

private struct StorableSelfUserClient: Equatable, Identifiable, Codable, Sendable {

    let id: String
    let type: StorableUserClientType
    let activationDate: Date?
    let label: String?
    let model: String?
    let deviceClass: StorableDeviceClass?
    let lastActiveDate: Date?
    let mlsPublicKeys: StorableMLSPublicKeys?
    let cookie: String?
    let capabilities: [StorableUserClientCapability]

}

private enum StorableDeviceClass: String, Codable, Sendable {

    case phone
    case tablet
    case desktop
    case legalhold

    init(_ value: WireAPI.DeviceClass) {
        switch value {
        case .phone:
            self = .phone
        case .tablet:
            self = .tablet
        case .desktop:
            self = .desktop
        case .legalhold:
            self = .legalhold
        }
    }

    func toAPIModel() -> WireAPI.DeviceClass {
        switch self {
        case .phone:
            .phone
        case .tablet:
            .tablet
        case .desktop:
            .desktop
        case .legalhold:
            .legalhold
        }
    }

}

private struct StorableMLSPublicKeys: Equatable, Codable, Sendable {

    let ed25519: String?
    let ed448: String?
    let p256: String?
    let p384: String?
    let p512: String?

}

private enum StorableUserClientCapability: String, Codable, Sendable {

    case legalholdConsent
    case consumableNotifications

    init(_ value: WireAPI.UserClientCapability) {
        switch value {
        case .legalholdConsent:
            self = .legalholdConsent
        case .consumableNotifications:
            self = .consumableNotifications
        }
    }

    func toAPIModel() -> WireAPI.UserClientCapability {
        switch self {
        case .legalholdConsent:
            .legalholdConsent
        case .consumableNotifications:
            .consumableNotifications
        }
    }

}

private enum StorableUserClientType: String, Codable, Sendable {

    case permanent
    case temporary
    case legalhold

    init(_ value: WireAPI.UserClientType) {
        switch value {
        case .permanent:
            self = .permanent
        case .temporary:
            self = .temporary
        case .legalhold:
            self = .legalhold
        }
    }

    func toAPIModel() -> WireAPI.UserClientType {
        switch self {
        case .permanent:
            .permanent
        case .temporary:
            .temporary
        case .legalhold:
            .legalhold
        }
    }

}
