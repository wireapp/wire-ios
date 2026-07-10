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

class UpdateEventsAPIV5: UpdateEventsAPIV4 {

    override var apiVersion: APIVersion {
        .v5
    }

    private var basePath: String {
        "/notifications"
    }

    override func getLastUpdateEvent(selfClientID: String?) async throws -> UpdateEventEnvelope {
        let path = "\(pathPrefix)\(basePath)/last"

        var requestBuilder = try URLRequestBuilder(path: path)
            .withMethod(.get)

        if let selfClientID {
            requestBuilder = requestBuilder.withQueryItem(
                name: "client",
                value: selfClientID
            )
        }

        let request = requestBuilder.build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        // Change: 400 error removed.
        return try ResponseParser()
            .success(code: .ok, type: UpdateEventEnvelopeV0.self)
            .failure(code: .notFound, label: "not-found", error: UpdateEventsAPIError.notFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get events since

    override func getUpdateEvents(
        selfClientID: String?,
        sinceEventID: UUID?
    ) -> PayloadPager<UpdateEventBatch> {
        let resourcePath = "\(pathPrefix)\(basePath)"

        return PayloadPager(start: sinceEventID?.transportString()) { nextSince in
            var requestBuilder = try URLRequestBuilder(path: resourcePath)
                .withMethod(.get)
                .withQueryItem(name: "size", value: "500")

            if let nextSince {
                requestBuilder = requestBuilder.withQueryItem(name: "since", value: nextSince)
            }

            if let selfClientID {
                requestBuilder = requestBuilder.withQueryItem(
                    name: "client",
                    value: selfClientID
                )
            }

            let request = requestBuilder.build()

            let (data, response) = try await self.apiService.executeRequest(
                request,
                requiringAccessToken: true
            )
            // Change: 400 error removed.
            return try ResponseParser()
                .success(code: .ok, type: UpdateEventListResponseV0.self)
                .failure(code: .notFound, error: UpdateEventsAPIError.notFound)
                .parse(code: response.statusCode, data: data)
        }
    }

}
