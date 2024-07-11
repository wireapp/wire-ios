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

public protocol ImportMessagesUseCaseProtocol {

    func invoke(backupURL: URL) async throws

}

public enum ImportMessagesUseCaseError: LocalizedError {

    case backupResourceUnavailable
    case failedToUnzipBackup
    case decodingError(Error)
    case failedToSaveDatabase(Error)

    public var errorDescription: String? {
        switch self {
        case .backupResourceUnavailable:
            "The backup file is unavailable"

        case .failedToUnzipBackup:
            "The backup file could not be unzipped"

        case .decodingError(let error):
            "The backup file could not be decoded: \(error)"

        case .failedToSaveDatabase(let error):
            "The database could not be saved: \(error)"
        }
    }

}

public struct ImportMessagesUseCase: ImportMessagesUseCaseProtocol {

    private let syncContext: NSManagedObjectContext

    public init(syncContext: NSManagedObjectContext) {
        self.syncContext = syncContext
    }

    public func invoke(backupURL: URL) async throws {
        guard backupURL.startAccessingSecurityScopedResource() else {
            throw ImportMessagesUseCaseError.backupResourceUnavailable
        }

        defer {
            backupURL.stopAccessingSecurityScopedResource()
        }

        let unzippedURL = temporaryURL(for: backupURL)

        guard backupURL.unzip(to: unzippedURL) else {
            throw ImportMessagesUseCaseError.failedToUnzipBackup
        }

        let metadataURL = unzippedURL.appendingPathComponent("export.json")
        let metadata = try decodeBackupModel(MetadataBackupModel.self, from: metadataURL)

        // TODO: guard it's for self user

        let eventsURL = unzippedURL.appendingPathComponent("events.json")
        let events = try decodeBackupModel([EventBackupModel].self, from: eventsURL)

        let messages = events.compactMap {
            switch $0 {
            case .messageAdd(let eventData):
                eventData
            default:
                nil
            }
        }

        try await syncContext.perform { [self] in
            for backup in messages {
                // TODO: only create if message doesn't already exist
                let genericMessage = GenericMessage(
                    content: Text(content: backup.content),
                    nonce: backup.nonce
                )

                let message = ZMClientMessage(
                    nonce: backup.nonce,
                    managedObjectContext: syncContext
                )

                try message.setUnderlyingMessage(genericMessage)
                message.serverTimestamp = backup.time

                message.sender = ZMUser.fetchOrCreate(
                    with: backup.senderUserID,
                    domain: nil,
                    in: syncContext
                )

                if let senderClientID = backup.senderClientID {
                    message.senderClientID = senderClientID
                } else {
                    // Message is from self user
                    message.delivered = true
                }

                message.visibleInConversation = ZMConversation.fetchOrCreate(
                    with: backup.conversationID,
                    domain: nil,
                    in: syncContext
                )
            }

            do {
                try syncContext.save()
            } catch {
                throw ImportMessagesUseCaseError.failedToSaveDatabase(error)
            }
        }

        // TODO: clean up temp file
    }

    private func temporaryURL(for url: URL) -> URL {
        url.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
    }

    private func decodeBackupModel<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) throws -> T {
        do {
            let decoder = JSONDecoder.defaultDecoder
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ImportMessagesUseCaseError.decodingError(error)
        }
    }

}
