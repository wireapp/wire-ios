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

import WireCoreCrypto
import WireDataModel
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

    func sendCommitBundle(commitBundle: WireCoreCryptoUniffi.CommitBundle) async throws {
        let events: [UpdateEvent]

        do {
            events = try await mlsAPI.postCommitBundle(commitBundle.toAPIModel())
        } catch let error as MLSAPIError {
            let reason = (try? encodeErrorReason(error)) ?? "failed to encode error"
            throw WireCoreCrypto.MlsTransportError.MessageRejected(reason: reason)
        } catch {
            throw WireCoreCrypto.MlsTransportError.MessageRejected(reason: error.localizedDescription)
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
    }

    private func encodeErrorReason(_ error: MLSAPIError) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodableError = MLSTransportError(error)
        return String(decoding: try encoder.encode(encodableError), as: UTF8.self)
    }

    func sendMessage(mlsMessage: Data) async throws {
        throw WireCoreCrypto.MlsTransportError.MessageRejected(reason: "not implemented")
    }

    func prepareForTransport(historySecret: WireCoreCryptoUniffi.HistorySecret) async -> WireCoreCryptoUniffi
        .MlsTransportData {
        // TODO: [WPB-19197] implement `prepareForTransport(historySecret:)`
        fatalError("not implemented")
    }

}
