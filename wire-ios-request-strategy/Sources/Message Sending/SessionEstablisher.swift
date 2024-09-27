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

// MARK: - SessionEstablisherError

public enum SessionEstablisherError: Error, Equatable {
    case missingSelfClient
}

// MARK: - SessionEstablisherInterface

// sourcery: AutoMockable
public protocol SessionEstablisherInterface {
    func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws
}

// MARK: - SessionEstablisher

public class SessionEstablisher: SessionEstablisherInterface {
    public init(
        context: NSManagedObjectContext,
        apiProvider: APIProviderInterface,
        processor: PrekeyPayloadProcessorInterface = PrekeyPayloadProcessor()
    ) {
        self.processor = processor
        self.apiProvider = apiProvider
        self.context = context
    }

    private let apiProvider: APIProviderInterface
    private let context: NSManagedObjectContext
    private let processor: PrekeyPayloadProcessorInterface
    private let batchSize = 28

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        // Establish sessions in chunks
        for chunk in Array(clients).chunked(into: batchSize) {
            try await internalEstablishSessions(for: Set(chunk), apiVersion: apiVersion)
        }
    }

    private func internalEstablishSessions(for clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        guard let selfClient = await context.perform({
            ZMUser.selfUser(in: self.context).selfClient()
        }) else {
            throw SessionEstablisherError.missingSelfClient
        }

        let prekeys = try await apiProvider.prekeyAPI(apiVersion: apiVersion).fetchPrekeys(for: clients)

        _ = await processor.establishSessions(from: prekeys, with: selfClient, context: context)
    }
}

extension Array {
    fileprivate func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
