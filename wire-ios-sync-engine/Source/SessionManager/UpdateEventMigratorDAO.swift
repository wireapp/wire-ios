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

@preconcurrency import CoreData
import Foundation
import WireNetwork
import WireUpdateEventCoding

protocol UpdateEventMigratorDAOProtocol {

    func existsLegacyEvent() async throws -> Bool
    func indexOfLastEventEnvelope() async throws -> Int64
    func nextBatchOfLegacyEvents(privateKeys: EARPrivateKeys?) async -> [ZMUpdateEvent]?
    func insertEventEnvelope(_ eventEnvelope: UpdateEventEnvelope, index: Int64) async throws
    func deleteNextBatchOfLegacyEvents() async
    func save() async throws
    func discardChanges() async

}

struct UpdateEventMigratorDAO: UpdateEventMigratorDAOProtocol {

    private let context: NSManagedObjectContext
    private let encoder = StorableUpdateEventCoder()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func existsLegacyEvent() async throws -> Bool {
        try await context.perform {
            let request = StoredUpdateEvent.fetchRequest()
            return try context.count(for: request) > 0
        }
    }

    func indexOfLastEventEnvelope() async throws -> Int64 {
        try await context.perform {
            let request = StoredUpdateEventEnvelope.lastObjectFetchRequest
            let lastEnvelope = try context.fetch(request).first
            return lastEnvelope?.sortIndex ?? 0
        }
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
                    legacyEvent

                case .failure:
                    nil
                }
            }

            guard !legacyEvents.isEmpty else {
                return nil
            }

            return legacyEvents
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

    func deleteNextBatchOfLegacyEvents() async {
        await context.perform {
            StoredUpdateEvent.nextEvents(
                context,
                batchSize: 500,
                callEventsOnly: false
            ).forEach {
                context.delete($0)
            }
        }
    }

    func save() async throws {
        try await context.perform {
            try context.save()
        }
    }

    func discardChanges() async {
        await context.perform {
            context.rollback()
        }
    }

}

@available(iOS 17, *)
actor ActorBasedUpdateEventMigratorDAO: UpdateEventMigratorDAOProtocol {

    private nonisolated
    let contextExecutor: ContextExecutor

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        contextExecutor.asUnownedSerialExecutor()
    }

    private var context: NSManagedObjectContext {
        contextExecutor.context
    }

    private let encoder = StorableUpdateEventCoder()

    init(container: NSPersistentContainer) {
        self.init(context: container.newBackgroundContext())
    }

    init(context: NSManagedObjectContext) {
        self.contextExecutor = ContextExecutor(context: context)
    }

    func existsLegacyEvent() async throws -> Bool {
        let request = StoredUpdateEvent.fetchRequest()
        return try context.count(for: request) > 0
    }

    func nextBatchOfLegacyEvents(privateKeys: EARPrivateKeys?) async -> [ZMUpdateEvent]? {
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
                legacyEvent

            case .failure:
                nil
            }
        }

        guard !legacyEvents.isEmpty else {
            return nil
        }

        return legacyEvents
    }

    func indexOfLastEventEnvelope() async throws -> Int64 {
        let request = StoredUpdateEventEnvelope.lastObjectFetchRequest
        let lastEnvelope = try context.fetch(request).first
        return lastEnvelope?.sortIndex ?? 0
    }

    func insertEventEnvelope(
        _ eventEnvelope: UpdateEventEnvelope,
        index: Int64
    ) async throws {
        StoredUpdateEventEnvelope.insertNewObject(
            data: try encoder.encode(eventEnvelope),
            sortIndex: index,
            in: context
        )
    }

    func deleteNextBatchOfLegacyEvents() async {
        StoredUpdateEvent.nextEvents(
            context,
            batchSize: 500,
            callEventsOnly: false
        ).forEach {
            context.delete($0)
        }
    }

    func save() async throws {
        try context.save()
    }

    func discardChanges() async {
        context.rollback()
    }

}

@available(iOS 17, *)
final class ContextExecutor: SerialExecutor {

    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // Disabling this rule because wants to remove `consuming`
    // but then the Swift compiler complains.
    // swiftformat:disable:next noExplicitOwnership
    func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        let unownedExecutor = asUnownedSerialExecutor()

        context.perform {
            unownedJob.runSynchronously(on: unownedExecutor)
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

}
