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
import WireSystem

// MARK: - HTTPClientImpl

// Note: this is just a tempory helper for debugging
// purposes and should eventually be removed.

private class HTTPClientImpl: HTTPClient {
    // MARK: Lifecycle

    public init(
        transportSession: TransportSessionType,
        queue: GroupQueue
    ) {
        self.transportSession = transportSession
        self.queue = queue
    }

    // MARK: Public

    public func executeRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        await withCheckedContinuation { continuation in

            let request = request.toZMTransportRequest()
            request.add(ZMCompletionHandler(on: queue) { response in
                let response = response.toHTTPResponse()
                continuation.resume(returning: response)
            })

            transportSession.enqueueOneTime(request)
        }
    }

    // MARK: Internal

    let transportSession: TransportSessionType
    let queue: GroupQueue
}

extension HTTPRequest {
    fileprivate func toZMTransportRequest() -> ZMTransportRequest {
        .init(
            path: path,
            method: method.toZMTransportRequestMethod(),
            payload: body.map { String(decoding: $0, as: UTF8.self) } as? ZMTransportData,
            apiVersion: 0
        )
    }
}

extension HTTPRequest.Method {
    fileprivate func toZMTransportRequestMethod() -> ZMTransportRequestMethod {
        switch self {
        case .delete:
            .delete
        case .get:
            .get
        case .head:
            .head
        case .post:
            .post
        case .put:
            .put
        }
    }
}

extension ZMTransportResponse {
    fileprivate func toHTTPResponse() -> HTTPResponse {
        HTTPResponse(
            code: httpStatus,
            payload: rawData
        )
    }
}
