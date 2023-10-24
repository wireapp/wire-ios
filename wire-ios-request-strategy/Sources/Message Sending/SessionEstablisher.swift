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

public enum SessionEstablisherError: Error {
    case failedToGenerateRequest
    case failedToParseResponse
}

public class SessionEstablisher {

    public init(
        httpClient: HttpClient,
        apiVersion: APIVersion,
        context: NSManagedObjectContext
    ) {
        self.httpClient = httpClient
        self.apiVersion = apiVersion
        self.managedObjectContext = context
    }

    private let httpClient: HttpClient
    private let apiVersion: APIVersion
    private let managedObjectContext: NSManagedObjectContext
    private let requestFactory = MissingClientsRequestFactory()
    private let processor = PrekeyPayloadProcessor()

    func establishSession(with clients: Set<UserClient>) async -> Swift.Result<Void, SessionEstablisherError> {

        // Establish sessions in chunks and return on first error
        for chunk in Array(clients).chunked(into: 28) {
            let result = await internalEstablishSessions(for: Set(chunk))
            if case Swift.Result.failure = result {
                return result
            }
        }

        return .success(Void())
    }

    private func internalEstablishSessions(for clients: Set<UserClient>) async -> Swift.Result<Void, SessionEstablisherError> {
        let request = managedObjectContext.performAndWait {
            return switch apiVersion {
            case .v0:
                requestFactory.fetchPrekeys(for: clients, apiVersion: apiVersion)?.transportRequest
            case .v1, .v2, .v3, .v4, .v5:
                requestFactory.fetchPrekeysFederated(for: clients, apiVersion: apiVersion)?.transportRequest
            }
        }

        guard let request = request else {
            return .failure(SessionEstablisherError.failedToGenerateRequest)
        }

        let response = await httpClient.send(request)

        return managedObjectContext.performAndWait {
            establishSessionsFromPrekeyResponse(response: response)
        }
    }

    private func establishSessionsFromPrekeyResponse(response: ZMTransportResponse) -> Swift.Result<Void, SessionEstablisherError> {
        switch apiVersion {
        case .v0:
            guard
                let rawData = response.rawData,
                let prekeys = Payload.PrekeyByUserID(rawData),
                let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            else {
                return .failure(SessionEstablisherError.failedToParseResponse)
            }

            _ = processor.establishSessions(
                from: prekeys,
                with: selfClient,
                context: managedObjectContext
            )

        case .v1, .v2, .v3:
            guard
                let rawData = response.rawData,
                let prekeys = Payload.PrekeyByQualifiedUserID(rawData),
                let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            else {
                return .failure(SessionEstablisherError.failedToParseResponse)
            }

            _ = processor.establishSessions(
                from: prekeys,
                with: selfClient,
                context: managedObjectContext
            )

        case .v4, .v5:
            guard
                let rawData = response.rawData,
                let payload = Payload.PrekeyByQualifiedUserIDV4(rawData),
                let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            else {
                return .failure(SessionEstablisherError.failedToParseResponse)
            }

            let prekeys = payload.prekeyByQualifiedUserID
            _ = processor.establishSessions(
                from: prekeys,
                with: selfClient,
                context: managedObjectContext
            )
        }

        return .success(Void())
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
