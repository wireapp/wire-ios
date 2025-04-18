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

struct UpdateEventMigratorDAO {

    private let context: NSManagedObjectContext
    private let encoder = JSONEncoder()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func nextBatchOfLegacyEvents(privateKeys: EARPrivateKeys?) async -> [ZMUpdateEvent]? {
        await context.perform {
            let legacyEvents = StoredUpdateEvent.nextEvents(
                context,
                batchSize: 500,
                callEventsOnly: false
            )
            .compactMap {
                switch StoredUpdateEvent.extractUpdateEvent(
                    from: $0,
                    privateKeys: privateKeys
                ) {
                case let .success(legacyEvent):
                    return legacyEvent

                case .failure:
                    return nil
                }
            }

            guard !legacyEvents.isEmpty else {
                return nil
            }

            return legacyEvents
        }
    }

    func deleteAllLegacyEvents() async throws {
        try await context.perform {
            let fetchRequest = StoredUpdateEvent.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
    }

    func indexOfLastEventEnvelope() async throws -> Int64 {
        try await context.perform {
            let request = StoredUpdateEventEnvelope.lastObjectFetchRequest
            let lastEnvelope = try context.fetch(request).first
            return lastEnvelope?.sortIndex ?? 0
        }
    }

    func insertEventEnvelope(
        _ eventEnvelope: UpdateEventEnvelope,
        index: Int64
    ) async throws {
        try await context.perform {
            _ = StoredUpdateEventEnvelope.insertNewObject(
                data: try encoder.encode(eventEnvelope),
                sortIndex: index,
                in: context
            )
        }
    }

    func save() async throws {
        try await context.perform {
            try context.save()
        }
    }

}
