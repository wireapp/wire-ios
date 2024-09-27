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

private let zmLog = ZMSLog(tag: "ConversationLink")

// MARK: - ZMConversation.TransportKey

extension ZMConversation {
    fileprivate enum TransportKey {
        static let data = "data"
        static let uri = "uri"
        static let hasPassword = "has_password"
    }
}

// MARK: - WirelessLinkError

public enum WirelessLinkError: Error {
    case noCode
    case invalidResponse
    case invalidOperation
    case guestLinksDisabled
    case noConversation
    case unknown

    init?(response: ZMTransportResponse) {
        switch (response.httpStatus, response.payloadLabel()) {
        case (403, "invalid-op"?): self = .invalidOperation
        case (404, "no-conversation-code"?): self = .noCode
        case (404, "no-conversation"?): self = .noConversation
        case (409, "guest-links-disabled"?): self = .guestLinksDisabled
        case (400 ..< 499, _): self = .unknown
        default: return nil
        }
    }
}

extension ZMConversation {
    /// Fetches the wireless link for accessing the conversation.
    ///
    /// - Parameters:
    ///   - userSession: The user session used to fetch the link.
    ///   - completion: A closure called when the operation is completed. It returns a `Result` with either the link
    /// fetched
    ///                 along with its security status or an error.
    ///
    /// - Note: The completion closure is called with `.success` and the link fetched if successful. If the link has not
    /// been generated yet, it is called with `.success(nil)`. If there are any errors during the operation, it is
    /// called with `.failure` along with the corresponding error.
    public func fetchWirelessLink(
        in userSession: ZMUserSession,
        _ completion: @escaping (Result<(uri: String?, secured: Bool), Error>) -> Void
    ) {
        guard canManageAccess else {
            return completion(.failure(WirelessLinkError.invalidOperation))
        }

        guard let apiVersion = BackendInfo.apiVersion else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.fetchLinkRequest(for: self, apiVersion: apiVersion)
        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if response.httpStatus == 200,
               let payloadDict = response.payload?.asDictionary() {
                let hasPassword = payloadDict[ZMConversation.TransportKey.hasPassword] as? Bool ?? false
                if let uri = payloadDict[ZMConversation.TransportKey.uri] as? String {
                    completion(.success((uri: uri, secured: hasPassword)))
                } else {
                    completion(.failure(WirelessLinkError.invalidResponse))
                }
            } else if response.httpStatus == 404 {
                completion(.success((uri: nil, secured: false)))
            } else {
                // Handle other types of errors
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.debug("Error fetching wireless link: \(error)")
                completion(.failure(error))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    var isLegacyAccessMode: Bool {
        accessMode == [.invite]
    }

    /// Checks if a guest link can be generated or not
    public func canGenerateGuestLink(
        in userSession: ZMUserSession,
        _ completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let apiVersion = BackendInfo.apiVersion else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.guestLinkFeatureStatusRequest(for: self, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            switch response.httpStatus {
            case 200:
                guard
                    let payload = response.payload?.asDictionary(),
                    let data = payload["status"] as? String
                else {
                    return completion(.failure(WirelessLinkError.invalidResponse))
                }

                return completion(.success(data == "enabled"))

            case 404:
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.error("Could not check guest link status: \(error)")
                completion(.failure(error))

            default:
                completion(.failure(WirelessLinkError.unknown))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    /// Deletes the existing wireless link.
    public func deleteWirelessLink(
        in userSession: ZMUserSession,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard canManageAccess else {
            return completion(.failure(WirelessLinkError.invalidOperation))
        }

        guard let apiVersion = BackendInfo.apiVersion else {
            return completion(.failure(WirelessLinkError.unknown))
        }

        let request = WirelessRequestFactory.deleteLinkRequest(for: self, apiVersion: apiVersion)

        request.add(ZMCompletionHandler(on: managedObjectContext!) { response in
            if response.httpStatus == 200 {
                completion(.success(()))
            } else {
                let error = WirelessLinkError(response: response) ?? .unknown
                zmLog.debug("Error creating wireless link: \(error)")
                completion(.failure(error))
            }
        })

        userSession.transportSession.enqueueOneTime(request)
    }

    public var canManageAccess: Bool {
        guard let moc = managedObjectContext else { return false }
        let selfUser = ZMUser.selfUser(in: moc)
        return selfUser.canModifyAccessControlSettings(in: self)
    }
}

// MARK: - WirelessRequestFactory

enum WirelessRequestFactory {
    static func fetchLinkRequest(for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(getFromPath: "/conversations/\(identifier)/code", apiVersion: apiVersion.rawValue)
    }

    static func guestLinkFeatureStatusRequest(
        for conversation: ZMConversation,
        apiVersion: APIVersion
    ) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(
            getFromPath: "/conversations/\(identifier)/features/conversationGuestLinks",
            apiVersion: apiVersion.rawValue
        )
    }

    static func deleteLinkRequest(for conversation: ZMConversation, apiVersion: APIVersion) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }
        return .init(
            path: "/conversations/\(identifier)/code",
            method: .delete,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    static func setAccessRoles(
        allowGuests: Bool,
        allowServices: Bool,
        for conversation: ZMConversation,
        apiVersion: APIVersion
    ) -> ZMTransportRequest {
        guard let identifier = conversation.remoteIdentifier?.transportString() else {
            fatal("conversation is not yet inserted on the backend")
        }

        var accessRoles = conversation.accessRoles

        if allowServices {
            accessRoles.insert(.service)
        } else {
            accessRoles.remove(.service)
        }

        if allowGuests {
            accessRoles.insert(.guest)
            accessRoles.insert(.nonTeamMember)
        } else {
            accessRoles.remove(.guest)
            accessRoles.remove(.nonTeamMember)
        }

        var payload: [String: Any] = [
            "access": ConversationAccessMode.value(forAllowGuests: allowGuests).stringValue,
        ]
        let path: String

        switch apiVersion {
        case .v3, .v4, .v5, .v6:
            let domain = if let domain = conversation.domain, !domain.isEmpty { domain } else { BackendInfo.domain }
            guard let domain else {
                fatal("no domain associated with conversation, can't make the request")
            }
            path = "/conversations/\(domain)/\(identifier)/access"
            payload["access_role"] = accessRoles.map(\.rawValue)

        case .v2, .v1, .v0:
            path = "/conversations/\(identifier)/access"
            payload["access_role"] = ConversationAccessRole.fromAccessRoleV2(accessRoles).rawValue
            payload["access_role_v2"] = accessRoles.map(\.rawValue)
        }

        return .init(path: path, method: .put, payload: payload as ZMTransportData, apiVersion: apiVersion.rawValue)
    }
}
