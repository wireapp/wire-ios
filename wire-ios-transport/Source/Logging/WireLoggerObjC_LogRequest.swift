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

import Foundation
import WireLogging

extension WireLoggerObjC {
    static func logRequest(_ request: NSURLRequest) {
        WireLogger.network.log(request: request)
    }

    @objc(logHTTPResponse:body:)
    static func logHTTPResponse(_ response: HTTPURLResponse, body: Data?) {
        WireLogger.network.log(response: response, body: body)
    }

    @objc(logRequestLoopAtPath:)
    static func logRequestLoop(at path: String) {
        if let endpointDescription = URL(string: path)?.endpointRemoteLogDescription {
            WireLogger.network.warn("Request loop detected for \(endpointDescription)", attributes: .safePublic)
        } else {
            WireLogger.network.warn("Request loop detected for \(path)")
        }
    }
}
