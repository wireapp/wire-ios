//
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

public protocol HttpClient {

    func send(_ request: ZMTransportRequest) async -> ZMTransportResponse

}

public class HttpClientImpl: HttpClient {

    let transportSession: TransportSessionType
    let queue: ZMSGroupQueue

    public init(transportSession: TransportSessionType, queue: ZMSGroupQueue) {
        self.transportSession = transportSession
        self.queue = queue
    }

    public func send(_ request: ZMTransportRequest) async -> ZMTransportResponse {
        await withCheckedContinuation { continuation in
            request.add(ZMCompletionHandler(on: queue, block: { response in
                continuation.resume(returning: response)
            }))

            transportSession.enqueueOneTime(request)
        }
    }
}
