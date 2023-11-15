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

public enum NetworkError: Error {
    case errorEncodingRequest
    case errorDecodingResponse(ZMTransportResponse)
    case missingClients(Payload.MessageSendingStatus, ZMTransportResponse)
    case invalidRequestError(Payload.ResponseFailure, ZMTransportResponse)

    var response: ZMTransportResponse? {
        return switch self {
        case .errorEncodingRequest:
            nil
        case .errorDecodingResponse(let response):
            response
        case .missingClients(_, let response):
            response
        case .invalidRequestError(_, let response):
            response
        }
    }
}
