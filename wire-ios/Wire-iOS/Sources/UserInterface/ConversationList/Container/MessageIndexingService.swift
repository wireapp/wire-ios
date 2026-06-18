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
        guard embedder.isAvailable else { return }
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
        let messages = await syncContext.perform { [self] in
            self.fetchMessages(newerThan: since, in: syncContext)
        }
        guard !messages.isEmpty else { return }

        var newestTimestamp = since
        var addedCount = 0

        for msg in messages {
            guard let embedding = embedder.embed(msg.text) else { continue }
            await SemanticSearchIndex.shared.add(
                uri: msg.uri,
                conversationName: msg.conversationName,
                text: msg.text,
                timestamp: msg.timestamp,
                embedding: embedding
            )
            if msg.timestamp > newestTimestamp { newestTimestamp = msg.timestamp }
            addedCount += 1
        }

        if addedCount > 0 {
            lastIndexedDate = newestTimestamp
            try? await SemanticSearchIndex.shared.save()
        }
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
                uri: message.objectID.uriRepresentation().absoluteString,
                conversationName: conversationName,
                text: text,
                timestamp: timestamp
            )
        }
    }
}
