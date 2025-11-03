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
import WireLegacyLogging
import WireNetwork

public struct BackendEnvironmentStore {

    private let directory: URL
    private let fileManager = FileManager.default

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(directory: URL) throws {
        self.directory = directory
        try fileManager.createAndProtectDirectory(at: directory)
    }

    public func storeBackendEnvironment(
        _ backendEnvironment: BackendEnvironment2,
        for accountID: UUID
    ) throws {
        let accountDataURL = accountDataURL(id: accountID)
        let path = accountDataURL.path(percentEncoded: false)
        if !fileManager.fileExists(atPath: path) {
            try fileManager.createAndProtectDirectory(at: accountDataURL)
        }
        let storedBackendEnvironment = backendEnvironment.toStored()
        let url = backendEnvironmentURL(for: accountID)
        let data = try encoder.encode(storedBackendEnvironment)
        try data.write(to: url, options: .atomic)
    }

    public func storeBackendMetadata(
        _ metadata: ResolvedBackendMetadata,
        for accountID: UUID
    ) throws {
        let accountDataURL = accountDataURL(id: accountID)
        let path = accountDataURL.path(percentEncoded: false)
        if !fileManager.fileExists(atPath: path) {
            try fileManager.createAndProtectDirectory(at: accountDataURL)
        }
        let storedBackendMetadata = metadata.toStored()
        let url = backendMetadataURL(for: accountID)
        let data = try encoder.encode(storedBackendMetadata)
        try data.write(to: url, options: .atomic)
    }

    public func fetchBackendEnvironment(accountID: UUID) throws -> BackendEnvironment2? {
        let url = backendEnvironmentURL(for: accountID)

        do {
            let data = try Data(contentsOf: url)
            let stored = try decoder.decode(
                StoredBackendEnvironment.self,
                from: data
            )
            return try stored.toDomain()
        } catch {
            let nsError = error as NSError
            if
                nsError.domain == NSCocoaErrorDomain,
                nsError.code == NSFileReadNoSuchFileError {
                return nil
            }

            throw error
        }
    }

    public func fetchBackendMetadata(accountID: UUID) throws -> ResolvedBackendMetadata? {
        let url = backendMetadataURL(for: accountID)

        do {
            let data = try Data(contentsOf: url)
            let stored = try decoder.decode(
                StoredResolvedBackendMetadata.self,
                from: data
            )
            return try stored.toDomain()
        } catch {
            let nsError = error as NSError
            if
                nsError.domain == NSCocoaErrorDomain,
                nsError.code == NSFileReadNoSuchFileError {
                return nil
            }

            throw error
        }
    }

    public func deleteBackendData(accountID: UUID) throws {
        for fileURL in [
            backendEnvironmentURL(for: accountID),
            backendMetadataURL(for: accountID)
        ] where fileManager.fileExists(atPath: fileURL.path(percentEncoded: false)) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Private Helper

    private func backendEnvironmentURL(for id: UUID) -> URL {
        accountDataURL(id: id)
            .appendingPathComponent("backend-environment.json")
    }

    private func backendMetadataURL(for id: UUID) -> URL {
        accountDataURL(id: id)
            .appendingPathComponent("backend-metadata.json")
    }

    private func accountDataURL(id: UUID) -> URL {
        directory
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

}
