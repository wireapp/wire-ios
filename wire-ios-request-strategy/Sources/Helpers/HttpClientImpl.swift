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

import WireSystem
import WireTransport

public struct HttpClientImpl: HttpClient {
    // MARK: Lifecycle

    public init(transportSession: any TransportSessionType, queue: any GroupQueue) {
        self.transportSession = transportSession
        self.queue = queue
    }

    // MARK: Public

    public func send(_ request: ZMTransportRequest) async -> ZMTransportResponse {
        await withCheckedContinuation { continuation in
            let handler = ZMCompletionHandler(on: queue) { response in
                continuation.resume(returning: response)
            }
            request.add(handler)

            transportSession.enqueueOneTime(request)
        }
    }

    // MARK: Internal

    let transportSession: any TransportSessionType
    let queue: any GroupQueue
}
