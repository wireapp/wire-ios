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
import WireAPI

extension ZMUserSession {

    public func writeContinouslyToCoreCrypto() {
        Task {
            let backgroundTaskManager = BackgroundActivityFactory.shared
            guard let activity = backgroundTaskManager.startBackgroundActivity(name: "Writing To CoreCrypto") else { return }
            guard let sessionID = await managedObjectContext.perform({
                let selfUser = ZMUser.selfUser(in: self.managedObjectContext)
                let selfClient = selfUser.selfClient()
                let otherClient = selfUser.clients.first(where: { $0 != selfClient })
                return otherClient?.proteusSessionID
            }) else {
                return
            }

            let cc = try await coreCryptoProvider.coreCrypto()

             try await cc.perform { cc in
                while true {
                    try await cc.proteusSessionSave(sessionId: sessionID.rawValue)
                }
            }
            backgroundTaskManager.endBackgroundActivity(activity)
        }
    }

}

// Note: this is just a tempory helper for debugging
// purposes and should eventually be removed.

extension ZMUserSession {

    public func makeBackendInfoAPI() -> BackendInfoAPI {
        let httpClient = HTTPClientImpl(
            transportSession: transportSession,
            queue: syncContext
        )

        return BackendInfoAPIBuilder(httpClient: httpClient)
            .makeAPI(for: .v0)
    }

}

private class HTTPClientImpl: HTTPClient {

    let transportSession: TransportSessionType
    let queue: ZMSGroupQueue

    public init(
        transportSession: TransportSessionType,
        queue: ZMSGroupQueue
    ) {
        self.transportSession = transportSession
        self.queue = queue
    }

    public func executeRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        await withCheckedContinuation { continuation in
            let request = request.toZMTransportRequest()
            request.add(ZMCompletionHandler(on: queue, block: { response in
                let response = response.toHTTPResponse()
                continuation.resume(returning: response)
            }))

            transportSession.enqueueOneTime(request)
        }
    }

}

private extension HTTPRequest {

    func toZMTransportRequest() -> ZMTransportRequest {
        return ZMTransportRequest(
            path: path,
            method: method.toZMTransportRequestMethod(),
            payload: body as? ZMTransportData,
            apiVersion: 0
        )
    }

}

private extension HTTPRequest.Method {

    func toZMTransportRequestMethod() -> ZMTransportRequestMethod {
        switch self {
        case .delete:
            return .delete
        case .get:
            return .get
        case .head:
            return .head
        case .post:
            return .post
        case .put:
            return .put
        }
    }

}

private extension ZMTransportResponse {

    func toHTTPResponse() -> HTTPResponse {
        return HTTPResponse(
            code: httpStatus,
            payload: rawData
        )
    }

}
