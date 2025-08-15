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

import WireCoreCrypto
import WireLogging
import WireNetwork

final class MLSTransportImpl: MlsTransport {

    let mlsAPI: MLSAPI
    let conversationEventProcessor: ConversationEventProcessorProtocol

    init(
        mlsAPI: MLSAPI,
        conversationEventProcessor: ConversationEventProcessorProtocol
    ) {
        self.mlsAPI = mlsAPI
        self.conversationEventProcessor = conversationEventProcessor
    }

    func sendCommitBundle(commitBundle: WireCoreCryptoUniffi.CommitBundle) async -> WireCoreCryptoUniffi
        .MlsTransportResponse {
        let events: [UpdateEvent]

        do {
            events = try await mlsAPI.postCommitBundle(commitBundle.toAPIModel())
        } catch let error as MLSAPIError {
            do {
                return .abort(reason: try error.encodeAsString())
            } catch {
                return .abort(reason: "failed to encode error")
            }
        } catch {
            return .abort(reason: error.localizedDescription)
        }

        for event in events {
            do {
                if case let .conversation(conversationEvent) = event {
                    try await conversationEventProcessor.processEvent(conversationEvent)
                }
            } catch {
                WireLogger.mls
                    .error(
                        "Commit bundle was accepted by the backend so can't roll back after failing to process conversation event)"
                    )
            }
        }

        return .success
    }

    func sendMessage(mlsMessage: Data) async -> WireCoreCryptoUniffi.MlsTransportResponse {
        .abort(reason: "not implemented")
    }

    func prepareForTransport(historySecret: WireCoreCryptoUniffi.HistorySecret) async -> WireCoreCryptoUniffi
        .MlsTransportData {
        // TODO: [WPB-19197] implement `prepareForTransport(historySecret:)`
        fatalError("not implemented")
    }

}
