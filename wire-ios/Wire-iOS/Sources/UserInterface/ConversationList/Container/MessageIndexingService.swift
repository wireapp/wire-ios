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

import CoreData
import WireDataModel
import WireLogging
import WireMessagingDomain
import WireSyncEngine

/// Runs at startup (on a background task) to embed text messages into the
/// semantic search index. Uses a UserDefaults timestamp to only process
/// messages that arrived since the last indexing run.
final class MessageIndexingService {

    private static let lastIndexedKey = "semantic_search_last_indexed_timestamp"
    private static let batchSize = 2_000

    private let userSession: ZMUserSession
    private let embedder = MessageEmbedder()

    init(userSession: ZMUserSession) {
        self.userSession = userSession
    }

    func startIndexingInBackground() {
        guard embedder.isAvailable else {
            WireLogger.search.warn("NLEmbedding sentence model unavailable — semantic indexing skipped")
            return
        }
        WireLogger.search.info("Starting semantic message indexing")
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            await SemanticSearchIndex.shared.load()
            await self.indexNewMessages()
        }
    }

    // MARK: - Private

    private var lastIndexedDate: Date {
        get { UserDefaults.standard.object(forKey: Self.lastIndexedKey) as? Date ?? .distantPast }
        set { UserDefaults.standard.set(newValue, forKey: Self.lastIndexedKey) }
    }

    private func indexNewMessages() async {
        let syncContext = userSession.syncContext

        let since = lastIndexedDate
        WireLogger.search.debug("Fetching messages newer than \(since)")

        let messages = await syncContext.perform { [self] in
            self.fetchMessages(newerThan: since, in: syncContext)
        }

        guard !messages.isEmpty else {
            WireLogger.search.info("No new messages to index")
            return
        }

        let total = messages.count
        WireLogger.search.info("Indexing \(total) messages")
        postProgress(indexed: 0, total: total)

        var newestTimestamp = since
        var addedCount = 0
        var skippedCount = 0

        for (i, msg) in messages.enumerated() {
            guard let embedding = embedder.embed(msg.text) else {
                skippedCount += 1
                continue
            }
            await SemanticSearchIndex.shared.add(
                uri: msg.uri,
                conversationName: msg.conversationName,
                text: msg.text,
                timestamp: msg.timestamp,
                embedding: embedding
            )
            if msg.timestamp > newestTimestamp { newestTimestamp = msg.timestamp }
            addedCount += 1

            if (i + 1).isMultiple(of: 50) || i + 1 == total {
                postProgress(indexed: i + 1, total: total)
            }
        }

        WireLogger.search.info("Indexed \(addedCount) messages, skipped \(skippedCount)")
        postProgress(indexed: total, total: total)

        if addedCount > 0 {
            lastIndexedDate = newestTimestamp
            do {
                try await SemanticSearchIndex.shared.save()
                WireLogger.search.info("Index saved to disk")
            } catch {
                WireLogger.search.error("Failed to save index: \(error)")
            }
        }
    }

    private func postProgress(indexed: Int, total: Int) {
        NotificationCenter.default.post(
            name: .semanticIndexingProgress,
            object: nil,
            userInfo: [
                SemanticSearchIndex.progressIndexedKey: indexed,
                SemanticSearchIndex.progressTotalKey: total
            ]
        )
    }

    private struct MessageRecord {
        let uri: String
        let conversationName: String
        let text: String
        let timestamp: Date
    }

    private func fetchMessages(newerThan since: Date, in context: NSManagedObjectContext) -> [MessageRecord] {
        let request = NSFetchRequest<ZMMessage>(entityName: ZMMessage.entityName())
        request.predicate = NSPredicate(
            format: "visibleInConversation != nil AND serverTimestamp > %@",
            since as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "serverTimestamp", ascending: false)]
        request.fetchLimit = Self.batchSize

        guard let messages = try? context.fetch(request) else { return [] }

        return messages.compactMap { message in
            guard
                let text = message.textMessageData?.messageText, !text.isEmpty,
                let timestamp = message.serverTimestamp,
                let conversationName = message.visibleInConversation?.displayName
            else { return nil }
            return MessageRecord(
                uri: message.objectID.uriRepresentation().absoluteString, // TODO: use id?
                conversationName: conversationName,
                text: text,
                timestamp: timestamp
            )
        }
    }
}
