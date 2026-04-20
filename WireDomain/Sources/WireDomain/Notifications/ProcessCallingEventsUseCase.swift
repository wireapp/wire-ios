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
import WireNetwork
import GenericMessageProtocol
import WireLogging
import CallKit
import WireDataModel

final class ProcessCallingEventsUseCase {

    private let callingService: any AVSCallingEventServiceProtocol
    private let clientID: String
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let isFederationEnabled: Bool
//    private var callKitReportTask: Task<Void, Never>?

    public init(
        callingService: any AVSCallingEventServiceProtocol,
        clientID: String,
        conversationLocalStore: any ConversationLocalStoreProtocol, isFederationEnabled: Bool,
        accountID: UUID
    ) {
        self.callingService = callingService
        self.clientID = clientID
        self.conversationLocalStore = conversationLocalStore
        self.isFederationEnabled = isFederationEnabled

//        var didReportIncomingCall = false

//        callingService.onIncomingCall = { conversationId, shouldRing, isVideoCall in
//            WireLogger.calling.info("WOW NSE calling: onIncomingCall fired, conversationId=\(conversationId), shouldRing=\(shouldRing)", attributes: .newNSE, .safePublic)
//
//            guard let qualifiedID = QualifiedID(rawValue: conversationId) else { return }
//
//            let callKitContent: [String: Any] = [
//                "accountID": accountID.uuidString,
//                "conversationID": qualifiedID.uuid.uuidString,
//                "shouldRing": shouldRing,
//                "hasVideo": isVideoCall,
//                "callerName": ""
//            ]
//
//            didReportIncomingCall = shouldRing
//            WireLogger.calling.error("12345 \(self == nil)", attributes: .newNSE, .safePublic)
//
//            self.callKitReportTask = Task {
//                await withCheckedContinuation { continuation in
//                    CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
//                        if let error {
//                            WireLogger.calling.error(
//                                "reportNewIncomingVoIPPushPayload error: \(error)",
//                                attributes: .newNSE, .safePublic
//                            )
//                        } else {
//                            WireLogger.calling.info(
//                                "reportNewIncomingVoIPPushPayload done",
//                                attributes: .newNSE, .safePublic
//                            )
//                        }
//                        continuation.resume()
//                    }
//                }
//            }
//        }
//
//        callingService.onMissedCall = { conversationId, messageTime, isVideoCall in
//            WireLogger.calling.info("WOW NSE calling: onMissedCall fired", attributes: .newNSE, .safePublic)
//            // Nothing to do here — the missed call text notification
//            // is already built by ConversationCallingEventNotificationBuilder
//            // from the same event in the event stream.
//            WireLogger.calling.info(
//                "AVS: missed call in conversation \(conversationId)",
//                attributes: .newNSE, .safePublic
//            )
//        }

//        callingService.onCallClosed = { reason, conversationId in
//            WireLogger.calling.info("WOW NSE calling: onCallClosed fired, reason=\(reason)", attributes: .newNSE, .safePublic)
//            guard didReportIncomingCall else { return }
//
//            let callKitContent: [String: Any] = [
//                "accountID": accountID.uuidString,
//                "conversationID": conversationId,
//                "shouldRing": false
//            ]
//
//            didReportIncomingCall = false
//
//            self.callKitReportTask = Task {
//                try? await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
//            }
//        }

    }

//    func invoke(eventBatches: [[UpdateEvent]]) async {
//        WireLogger.calling.info("WOW NSE calling: invoke started, batches=\(eventBatches.count)", attributes: .newNSE, .safePublic)
//        callingService.start()
//        WireLogger.calling.info("WOW NSE calling: start called", attributes: .newNSE, .safePublic)
//        for batch in eventBatches {
//            for event in batch {
//                WireLogger.calling.info("WOW NSE calling: will process event \(event)", attributes: .newNSE, .safePublic)
//                if let params = await avsParameters(from: event) {
//                    WireLogger.calling.info("WOW NSE calling: found AVS params,currentTime = \(params.currentTime), serverTime = \(params.serverTime), conversationId = \(params.conversationId), userId = \(params.userId), clientId = \(clientID), conversationType = \(params.conversationType)", attributes: .newNSE, .safePublic)
//                    callingService.process(
//                        data: params.data,
//                        currentTime: params.currentTime,
//                        serverTime: params.serverTime,
//                        conversationId: params.conversationId,
//                        userId: params.userId,
//                        clientId: clientID,
//                        conversationType: params.conversationType
//                    )
//                    WireLogger.calling.info("WOW NSE calling: did process event \(event)", attributes: .newNSE, .safePublic)
//
//                }
//            }
//        }
//        WireLogger.calling.info("WOW NSE calling: about to call end()", attributes: .newNSE, .safePublic)
//        callingService.end()
//        WireLogger.calling.info("WOW NSE calling: did call end()", attributes: .newNSE, .safePublic)
//        // Wait for CXProvider report to complete before returning —
//        // without this the NSE may terminate before the report fires.
////        _ = await callKitReportTask?.value
//        WireLogger.calling.info("WOW NSE calling: callKitReportTask awaited", attributes: .newNSE, .safePublic)
//    }

    func invoke(
        eventBatches: [[UpdateEvent]],
        callKitReportingCoordinator: CallKitReportingCoordinator
    ) async {
        callingService.start()

        for batch in eventBatches {
            for event in batch {
                if let params = await avsParameters(from: event) {
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


    private func avsParameters(from event: UpdateEvent) async -> AVSCallParams? {
        switch event {
        case .conversation(.proteusMessageAdd(let e)):
            WireLogger.calling.info(
                "WOW this is proteus conversation",
                attributes: .newNSE, .safePublic
            )
            return await avsParametersForProteus(e).first
        case .conversation(.mlsMessageAdd(let e)):
            WireLogger.calling.info(
                "WOW this is MLS conversation",
                attributes: .newNSE, .safePublic
            )
            return await avsParametersForMLS(e).first
        default:
            return nil
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
            WireLogger.calling.info(
                "WOW decryptedMessage is not nil",
                attributes: .newNSE, .safePublic
            )
            guard
                let payload = Data(base64Encoded: decryptedMessage.message),
                let genericMessage = GenericMessage(from: payload, validate: false),
                genericMessage.hasCalling,
                let callingData = genericMessage.calling.content.data(using: .utf8, allowLossyConversion: false),
                let clientID = decryptedMessage.senderClientID,
                let timestamp = event.timestamp                  
            else { continue }
            WireLogger.calling.info(
                "WOW hasCalling is true",
                attributes: .newNSE, .safePublic
            )
            WireLogger.calling.info(
                "WOW callingContent: \(genericMessage.calling.content)",
                attributes: .newNSE, .safePublic
            )
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
          // Prefer conversation ID embedded in the calling proto (mirrors WireCallCenterV3)
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

          // WCALL_CONV_TYPE: 0 = oneToOne, 1 = group (Proteus), 3 = conference_mls
          let conversationType: Int32 = if !isGroup {
              0  // WCALL_CONV_TYPE_ONEONONE
          } else if isMLS {
              3  // WCALL_CONV_TYPE_CONFERENCE_MLS
          } else {
              1  // WCALL_CONV_TYPE_GROUP
          }

          return AVSCallParams(
              data: callingData,
              currentTime: UInt32(Date.now.timeIntervalSince1970),
              serverTime: UInt32(timestamp.timeIntervalSince1970),
              conversationId: serialize(id: conversationUUID, domain: conversationDomain),
              userId: serialize(id: senderID.id, domain: senderID.domain),
              clientId: senderClientID,
              conversationType: conversationType
          )
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
 }
