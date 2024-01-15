////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public final class CreateGroupConversationAction: EntityAction {

    public typealias Result = NSManagedObjectID

    public enum Failure: Error, Equatable {

        case invalidBody
        case mlsNotEnabled
        case nonEmptyMemberList
        case missingLegalholdConsent
        case operationDenied
        case noTeamMember
        case notConnected
        case mlsMissingSenderClient
        case accessDenied
        case unreachableDomains(Set<String>)
        case nonFederatingDomains(Set<String>)
        case proccessingError
        case unknown(code: Int, label: String, message: String)

    }

    public var messageProtocol: MessageProtocol
    public var creatorClientID: String
    public var qualifiedUserIDs: [QualifiedID]
    public var unqualifiedUserIDs: [UUID]
    public var name: String?
    public var accessMode: ConversationAccessMode?
    public var accessRoles: Set<ConversationAccessRoleV2>
    public var legacyAccessRole: ConversationAccessRole?
    public var teamID: UUID?
    public var isReadReceiptsEnabled: Bool

    public var resultHandler: ResultHandler?

    public init(
        messageProtocol: MessageProtocol,
        creatorClientID: String,
        qualifiedUserIDs: [QualifiedID] = [],
        unqualifiedUserIDs: [UUID] = [],
        name: String? = nil,
        accessMode: ConversationAccessMode,
        accessRoles: Set<ConversationAccessRoleV2>,
        legacyAccessRole: ConversationAccessRole? = nil,
        teamID: UUID? = nil,
        isReadReceiptsEnabled: Bool,
        resultHandler: ResultHandler? = nil
    ) {
        self.messageProtocol = messageProtocol
        self.creatorClientID = creatorClientID
        self.qualifiedUserIDs = qualifiedUserIDs
        self.unqualifiedUserIDs = unqualifiedUserIDs
        self.name = name
        self.accessMode = accessMode
        self.accessRoles = accessRoles
        self.legacyAccessRole = legacyAccessRole
        self.teamID = teamID
        self.isReadReceiptsEnabled = isReadReceiptsEnabled
        self.resultHandler = resultHandler
    }

}

final class CreateGroupConversationActionHandler: ActionHandler<CreateGroupConversationAction> {

    private let processor = ConversationEventPayloadProcessor()
    private let mlsService: MLSServiceInterface

    required init(
        context: NSManagedObjectContext,
        mlsService: MLSServiceInterface
    ) {
        self.mlsService = mlsService

        super.init(context: context)
    }

    // MARK: - Request generation

    override func request(
        for action: CreateGroupConversationAction,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        let payload = Payload.NewConversation(action)
        guard let payloadString = payload.payloadString(apiVersion: apiVersion) else {
            return nil
        }

        return ZMTransportRequest(
            path: "/conversations",
            method: .post,
            payload: payloadString as ZMTransportData?,
            apiVersion: apiVersion.rawValue
        )
    }

    // MARK: - Response handling

    override func handleResponse(
        _ response: ZMTransportResponse,
        action: CreateGroupConversationAction
    ) {
        var action = action

        switch (response.httpStatus, response.payloadLabel()) {
        case (200, _), (201, _):
            Task { [action] in
                await handleSuccessResponse(response, action: action)
            }

        case (400, "mls-not-enabled"):
            action.fail(with: .mlsNotEnabled)

        case (400, "non-empty-member-list"):
            action.fail(with: .nonEmptyMemberList)

        case (400, _):
            action.fail(with: .invalidBody)

        case (403, "missing-legalhold-consent"):
            action.fail(with: .missingLegalholdConsent)

        case (403, "operation-denied"):
            action.fail(with: .operationDenied)

        case (403, "no-team-member"):
            action.fail(with: .noTeamMember)

        case (403, "not-connected"):
            action.fail(with: .notConnected)

        case (403, "mls-missing-sender-client"):
            action.fail(with: .mlsMissingSenderClient)

        case (403, "access-denied"):
            action.fail(with: .accessDenied)

        case (409, _):
            guard
                let payload = ErrorResponse(response),
                let nonFederatingDomains = payload.non_federating_backends
            else {
                return action.fail(with: .proccessingError)
            }

            if nonFederatingDomains.isEmpty {
                Task { [action] in
                    await handleSuccessResponse(response, action: action)
                }
            } else {
                action.fail(with: .nonFederatingDomains(Set(nonFederatingDomains)))
            }

        case (533, _):
            guard
                let payload = ErrorResponse(response),
                let unreachableDomains = payload.unreachable_backends
            else {
                return action.fail(with: .proccessingError)
            }

            if unreachableDomains.isEmpty {
                Task { [action] in
                    await handleSuccessResponse(response, action: action)
                }
            } else {
                action.fail(with: .unreachableDomains(Set(unreachableDomains)))
            }

        default:
            let errorInfo = response.errorInfo
            action.fail(with: .unknown(
                code: errorInfo.status,
                label: errorInfo.label,
                message: errorInfo.message
            ))
        }
    }

    private func handleSuccessResponse(
        _ response: ZMTransportResponse,
        action: CreateGroupConversationAction
    ) async {
        var action = action

        guard
            let apiVersion = APIVersion(rawValue: response.apiVersion),
            let rawData = response.rawData,
            let payload = Payload.Conversation(rawData, apiVersion: apiVersion),
            let newConversation = await self.processor.updateOrCreateConversation(
                from: payload,
                in: self.context
            )
        else {
            Logging.network.warn("Can't process response, aborting.")
            await context.perform {
                action.fail(with: .proccessingError)
            }
            return
        }

        let messageProtocol = await context.perform { newConversation.messageProtocol }

        switch messageProtocol {
        case .proteus:
            await context.perform {
                self.context.saveOrRollback()
                action.succeed(with: newConversation.objectID)
            }

        case .mls:
            Logging.mls.info("created new conversation on backend, got group ID (\(String(describing: payload.mlsGroupID)))")

            // Self user is creator, so we don't need to process a welcome message
            await context.perform {
                newConversation.mlsStatus = .ready
            }

            let selfUserID = await context.perform { ZMUser.selfUser(in: self.context).qualifiedID }

            // If this is an mls conversation, then the initial participants won't have
            // been added yet on the backend. This means that we must take the list of
            // participants from the action instead of the local conversation.
            let pendingParticipants = Set(action.qualifiedUserIDs).union(action.unqualifiedUserIDs.compactMap {
                guard let localDomain = BackendInfo.domain else { return nil }
                return QualifiedID(uuid: $0, domain: localDomain)
            })

            let users = pendingParticipants.map { qualifiedID in
                if qualifiedID == selfUserID {
                    return MLSUser(qualifiedID, selfClientID: action.creatorClientID)
                } else {
                    return MLSUser(qualifiedID)
                }
            }

            guard let groupID = await context.perform({ newConversation.mlsGroupID }) else {
                Logging.mls.warn("failed to create mls group: conversation is missing group id.")
                action.fail(with: .proccessingError)
                return
            }

            do {
                try await mlsService.createGroup(for: groupID, with: users)
                await self.context.perform {
                    action.succeed(with: newConversation.objectID)
                }
            } catch let error {
                Logging.mls.error("failed create new mls group: \(String(describing: error))")
                action.fail(with: .proccessingError)
                return
            }
        }
    }
}

extension CreateGroupConversationActionHandler {

    // MARK: - Error response

    struct ErrorResponse: Codable {

        var unreachable_backends: [String]?
        var non_federating_backends: [String]?

    }

}
