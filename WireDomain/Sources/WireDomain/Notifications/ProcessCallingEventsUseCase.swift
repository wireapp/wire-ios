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

import Foundation
import GenericMessageProtocol
import WireDataModel
import WireLogging
import WireNetwork

protocol ProcessCallingEventsUseCaseProtocol {
    func invoke(
        eventBatches: [[UpdateEvent]],
        callKitReportingCoordinator: CallKitReportingCoordinator
    ) async
}

/// Processes calling events collected during Notification Service Extension sync.
///
/// This use case opens an AVS calling-event batch, extracts call payloads from
/// synchronized Proteus and MLS message-add events, and forwards each call-related
/// event to `AVSCallingEventService`.
///
/// Once all event batches have been processed, it closes the AVS batch. AVS then
/// evaluates the final state of each call and triggers the callbacks registered by
/// `CallKitReportingCoordinator`, which reports the resulting actions to CallKit.
///
/// The use case waits for pending CallKit reporting work to complete before returning,
/// so the NSE can continue with regular notification generation.
final class ProcessCallingEventsUseCase: ProcessCallingEventsUseCaseProtocol {

    private let callingService: any AVSCallingEventServiceProtocol
    private let clientID: String
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let userLocalStore: any UserLocalStoreProtocol
    private let isFederationEnabled: Bool

    public init(
        callingService: any AVSCallingEventServiceProtocol,
        clientID: String,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol,
        isFederationEnabled: Bool,
        accountID: UUID
    ) {
        self.callingService = callingService
        self.clientID = clientID
        self.conversationLocalStore = conversationLocalStore
        self.userLocalStore = userLocalStore
        self.isFederationEnabled = isFederationEnabled
    }

    func invoke(
        eventBatches: [[UpdateEvent]],
        callKitReportingCoordinator: CallKitReportingCoordinator
    ) async {
        callingService.start()

        for batch in eventBatches {
            for event in batch {
                if let params = await avsParameters(from: event) {
                    WireLogger.mls.debug("🚀 setCallerName: callerName \(params.callerName)")
                    await callKitReportingCoordinator.setCallerName(
                        params.callerName,
                        for: params.conversationId
                    )
                    callingService.process(
                        data: params.data,
                        currentTime: params.currentTime,
                        serverTime: params.serverTime,
                        conversationId: params.conversationId,
                        userId: params.userId,
                        clientId: clientID,
                        conversationType: params.conversationType
                    )
                }
            }
        }

        callingService.end()

        await callKitReportingCoordinator.waitForCompletion()
    }

    // MARK: - Helpers

    private func avsParameters(from event: UpdateEvent) async -> AVSCallParams? {
        switch event {
        case let .conversation(.proteusMessageAdd(e)):
            await avsParametersForProteus(e).first
        case let .conversation(.mlsMessageAdd(e)):
            await avsParametersForMLS(e).first
        default:
            nil
        }
    }

    private func avsParametersForProteus(
        _ event: ConversationProteusMessageAddEvent
    ) async -> [AVSCallParams] {
        guard
            let decryptedBase64 = event.message.decryptedMessage,
            let payload = Data(base64Encoded: decryptedBase64),
            let genericMessage = GenericMessage(from: payload, validate: false),
            genericMessage.hasCalling,
            let callingData = genericMessage.calling.content.data(using: .utf8)
        else { return [] }

        let params = await buildParams(
            callingData: callingData,
            callingProto: genericMessage.calling,
            fallbackConversationID: event.conversationID,
            senderID: event.senderID,
            senderClientID: event.messageSenderClientID,
            timestamp: event.timestamp,
            isMLS: false
        )
        return params.map { [$0] } ?? []
    }

    private func avsParametersForMLS(
        _ event: ConversationMLSMessageAddEvent
    ) async -> [AVSCallParams] {
        var result: [AVSCallParams] = []

        for decryptedMessage in event.decryptedMessages {
            guard
                let payload = Data(base64Encoded: decryptedMessage.message),
                let genericMessage = GenericMessage(from: payload, validate: false),
                genericMessage.hasCalling,
                let callingData = genericMessage.calling.content.data(using: .utf8, allowLossyConversion: false),
                let clientID = decryptedMessage.senderClientID,
                let timestamp = event.timestamp
            else { continue }

            if let params = await buildParams(
                callingData: callingData,
                callingProto: genericMessage.calling,
                fallbackConversationID: event.conversationID,
                senderID: event.senderID,
                senderClientID: clientID,
                timestamp: timestamp,
                isMLS: true
            ) {
                result.append(params)
            }
        }

        return result
    }

    private func buildParams(
        callingData: Data,
        callingProto: Calling,
        fallbackConversationID: ConversationID,
        senderID: UserID,
        senderClientID: String,
        timestamp: Date,
        isMLS: Bool
    ) async -> AVSCallParams? {
        let callingConvID = callingProto.qualifiedConversationID
        let conversationUUID: UUID
        let conversationDomain: String?
        if !callingConvID.id.isEmpty, let uuid = UUID(uuidString: callingConvID.id) {
            conversationUUID = uuid
            conversationDomain = callingConvID.domain.isEmpty ? nil : callingConvID.domain
        } else {
            conversationUUID = fallbackConversationID.id
            conversationDomain = fallbackConversationID.domain
        }

        func serialize(id: UUID, domain: String?) -> String {
            if isFederationEnabled, let domain { return "\(id.transportString())@\(domain)" }
            return id.transportString()
        }

        let conversation = await conversationLocalStore.fetchOrCreateConversation(
            id: conversationUUID,
            domain: conversationDomain
        )
        let isGroup = await conversationLocalStore.isGroupConversation(conversation)
        let callerName = await makeCallKitTitle(
            conversation: conversation,
            senderID: senderID,
            isGroupConversation: isGroup
        )
        let avsConversationID = serialize(id: conversationUUID, domain: conversationDomain)
        let avsUserID = serialize(id: senderID.id, domain: senderID.domain)

        // WCALL_CONV_TYPE: 0 = oneToOne, 1 = group (Proteus), 3 = conference_mls.
        let conversationType: Int32 = if !isGroup {
            0
        } else if isMLS {
            3
        } else {
            1
        }
        WireLogger.mls.debug("🚀 Result: callerName \(callerName)")
        return AVSCallParams(
            data: callingData,
            currentTime: UInt32(Date.now.timeIntervalSince1970),
            serverTime: UInt32(timestamp.timeIntervalSince1970),
            conversationId: avsConversationID,
            userId: avsUserID,
            clientId: senderClientID,
            conversationType: conversationType,
            callerName: callerName
        )
    }

    private func makeCallKitTitle(
        conversation: ZMConversation,
        senderID: UserID,
        isGroupConversation: Bool
    ) async -> String? {
        let selfUser = await userLocalStore.fetchSelfUser()
        let caller = await userLocalStore.fetchOrCreateUser(
            id: senderID.id,
            domain: senderID.domain
        )
        let teamName = await userLocalStore.teamName(for: selfUser)
        let conversationName = await conversationLocalStore.name(for: conversation)
        let callerName = await userLocalStore.name(for: caller)

        WireLogger.mls.debug("🚀 teamName \(teamName)")
        WireLogger.mls.debug("🚀 conversationName \(conversationName)")
        WireLogger.mls.debug("🚀 callerName \(callerName)")
        let format: NotificationTitle.MessageTitleDescriptor? = if isGroupConversation, let conversationName {
            if let teamName {
                .conversationInTeam(conversation: conversationName, team: teamName)
            } else {
                .conversation(conversation: conversationName)
            }
        } else if let name = callerName ?? conversationName {
            if let teamName {
                .senderInTeam(sender: name, team: teamName)
            } else {
                .sender(sender: name)
            }
        } else {
            nil
        }

        guard let format else { return nil }
        WireLogger.mls.debug("🚀 format \(format)")

        return NotificationTitle
            .conversationMessage(format)
            .make()
    }

}

private struct AVSCallParams {
    let data: Data
    let currentTime: UInt32
    let serverTime: UInt32
    let conversationId: String
    let userId: String
    let clientId: String
    let conversationType: Int32
    let callerName: String?
}
