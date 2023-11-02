////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public enum SessionEstablisherError: Error, Equatable {
    case missingSelfClient
    case networkError(NetworkError)
}

public class SessionEstablisher {

    public init(
        context: NSManagedObjectContext,
        apiProvider: APIProviderInterface,
        processor: PrekeyPayloadProcessorInterface = PrekeyPayloadProcessor()
    ) {
        self.processor = processor
        self.apiProvider = apiProvider
        self.managedObjectContext = context
    }

    private let apiProvider: APIProviderInterface
    private let managedObjectContext: NSManagedObjectContext
    private let requestFactory = MissingClientsRequestFactory()
    private let processor: PrekeyPayloadProcessorInterface
    private let batchSize = 28

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async -> Swift.Result<Void, SessionEstablisherError> {

        // Establish sessions in chunks and return on first error
        for chunk in Array(clients).chunked(into: batchSize) {
            let result = await internalEstablishSessions(for: Set(chunk), apiVersion: apiVersion)
            if case Swift.Result.failure = result {
                return result
            }
        }

        return .success(Void())
    }

    private func internalEstablishSessions(for clients: Set<QualifiedClientID>, apiVersion: APIVersion) async -> Swift.Result<Void, SessionEstablisherError> {
        guard let selfClient = managedObjectContext.performAndWait({
            ZMUser.selfUser(in: managedObjectContext).selfClient()
        }) else {
            return .failure(SessionEstablisherError.missingSelfClient)
        }

        return await apiProvider.prekeyAPI(apiVersion: apiVersion).fetchPrekeys(for: clients)
            .mapError({ error in SessionEstablisherError.networkError(error) })
            .flatMap { prekeys in
            managedObjectContext.performAndWait {
                _ = processor.establishSessions(from: prekeys, with: selfClient, context: managedObjectContext)
                return Swift.Result.success(Void())
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
