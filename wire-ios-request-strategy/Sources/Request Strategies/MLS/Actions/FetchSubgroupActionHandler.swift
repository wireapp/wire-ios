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
import WireDataModel

class FetchSubgroupActionHandler: ActionHandler<FetchSubgroupAction> {
    // MARK: - Methods

    override func request(for action: FetchSubgroupAction, apiVersion: APIVersion) -> ZMTransportRequest? {
        var action = action

        guard apiVersion > .v3 else {
            action.fail(with: .endpointUnavailable)
            return nil
        }

        guard
            !action.domain.isEmpty,
            !action.conversationId.uuidString.isEmpty
        else {
            action.fail(with: .emptyParameters)
            return nil
        }

        return ZMTransportRequest(
            path: "/conversations/\(action.domain)/\(action.conversationId.transportString())/subconversations/\(action.type.rawValue)",
            method: .get,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    override func handleResponse(_ response: ZMTransportResponse, action: FetchSubgroupAction) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _):
            guard
                let data = response.rawData,
                let payload = Subgroup(data),
                let mlsSubgroup = payload.mlsSubgroup
            else {
                action.fail(with: .malformedResponse)
                return
            }
            action.succeed(with: mlsSubgroup)

        case (400, _):
            action.fail(with: .invalidParameters)

        case (403, "access-denied"):
            action.fail(with: .accessDenied)

        case (403, "mls-subconv-unsupported-convtype"):
            action.fail(with: .unsupportedConversationType)

        case (404, "no-conversation"):
            action.fail(with: .noConversation)

        case (404, _):
            action.fail(with: .conversationIdOrDomainNotFound)

        default:
            let errorInfo = response.errorInfo
            action.fail(with: .unknown(
                status: response.httpStatus,
                label: errorInfo.label,
                message: errorInfo.message
            ))
        }
    }
}

// MARK: Data structures

extension FetchSubgroupActionHandler {
    struct Subgroup: Codable {
        enum CodingKeys: String, CodingKey {
            case cipherSuite = "cipher_suite"
            case epoch
            case epochTimestamp = "epoch_timestamp"
            case groupID = "group_id"
            case members
            case parentQualifiedID = "parent_qualified_id"
            case subconvID = "subconv_id"
        }

        let cipherSuite: Int
        let epoch: Int
        let epochTimestamp: Date?
        let groupID: String
        let members: [SubgroupMember]
        let parentQualifiedID: SubgroupParent
        let subconvID: String
    }

    struct SubgroupMember: Codable {
        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case clientID = "client_id"
            case domain
        }

        let userID: UUID
        let clientID: String
        let domain: String
    }

    struct SubgroupParent: Codable {
        enum CodingKeys: String, CodingKey {
            case id
            case domain
        }

        let id: UUID
        let domain: String
    }
}

extension FetchSubgroupActionHandler.Subgroup {
    var mlsSubgroup: MLSSubgroup? {
        guard let groupID = MLSGroupID(base64Encoded: groupID) else {
            return nil
        }

        return MLSSubgroup(
            cipherSuite: cipherSuite,
            epoch: epoch,
            epochTimestamp: epochTimestamp,
            groupID: groupID,
            members: members.map(\.mlsClientID),
            parentQualifiedID: parentQualifiedID.qualifiedID
        )
    }
}

extension FetchSubgroupActionHandler.SubgroupParent {
    var qualifiedID: QualifiedID {
        QualifiedID(uuid: id, domain: domain)
    }
}

extension FetchSubgroupActionHandler.SubgroupMember {
    var mlsClientID: MLSClientID {
        MLSClientID(qualifiedClientID: qualifiedClientID)
    }

    var qualifiedClientID: QualifiedClientID {
        QualifiedClientID(userID: userID, domain: domain, clientID: clientID)
    }
}
