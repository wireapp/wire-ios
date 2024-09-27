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

public enum NetworkError: Error, Equatable {
    case errorEncodingRequest
    case errorDecodingResponse(ZMTransportResponse)
    case errorDecodingURLResponse(URLResponse)
    case endpointNotAvailable
    case missingClients(Payload.MessageSendingStatus, ZMTransportResponse)
    case invalidRequestError(Payload.ResponseFailure, ZMTransportResponse)

    // MARK: Public

    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.errorEncodingRequest, .errorEncodingRequest):
            true
        case (.errorDecodingResponse(_), .errorDecodingResponse(_)):
            true
        case let (.missingClients(lhsStatus, _), .missingClients(rhsStatus, _)):
            lhsStatus == rhsStatus
        case let (.invalidRequestError(lhsFailure, _), .invalidRequestError(rhsFailure, _)):
            lhsFailure == rhsFailure
        default:
            false
        }
    }

    // MARK: Internal

    var response: ZMTransportResponse? {
        switch self {
        case .errorEncodingRequest:
            nil
        case .endpointNotAvailable:
            nil
        case .errorDecodingURLResponse:
            nil
        case let .errorDecodingResponse(response):
            response
        case let .missingClients(_, response):
            response
        case let .invalidRequestError(_, response):
            response
        }
    }
}
