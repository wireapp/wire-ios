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

extension MockTransportSession {

    @objc
    public func processAPIVersionGetRequest(_ request: ZMTransportRequest) -> ZMTransportResponse {

        guard !isInternalError else {
            return ZMTransportResponse(payload: nil,
                                       httpStatus: 500,
                                       transportSessionError: nil,
                                       apiVersion: request.apiVersion)

        }

        // /api-version is the only unversioned endpoint.
        guard
            isAPIVersionEndpointAvailable,
            request.apiVersion == APIVersion.v0.rawValue
        else {
            return ZMTransportResponse(payload: nil,
                                       httpStatus: 404,
                                       transportSessionError: nil,
                                       apiVersion: request.apiVersion)
        }

        let payload: NSDictionary

        // development versions was added to the endpoint payload
        // at a later date, so we need to be able to mock both
        // the old and new response payloads.
        if developmentAPIVersions.isEmpty {
            payload = [
                "supported": supportedAPIVersions,
                "domain": domain,
                "federation": federation
            ]
        } else {
            payload = [
                "supported": supportedAPIVersions,
                "development": developmentAPIVersions,
                "domain": domain,
                "federation": federation
            ]
        }

        return ZMTransportResponse(
            payload: payload,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: request.apiVersion
        )
    }

}
