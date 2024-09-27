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

import WireDataModel
import WireSyncEngine
import Ziphy

// MARK: - ZiphySession

final class ZiphySession: ZiphyURLRequester {
    private let userSession: UserSession

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    func performZiphyRequest(
        _ request: URLRequest,
        completionHandler: @escaping ((Data?, URLResponse?, Error?) -> Void)
    ) -> ZiphyRequestIdentifier {
        // Removing the https://host part from the given URL, so WireSyncEngine can prepend it with the Wire giphy proxy
        // host
        // e.g. url = https://api.giphy.com/v1/gifs/trending?limit=50&offset=0
        //      requestPath = /v1/gifs/trending?limit=50&offset=0

        guard let requestPath = request.url?.urlWithoutSchemeAndHost else {
            preconditionFailure("request does not contain a valid URL")
        }

        return doRequest(
            withPath: requestPath,
            method: .get,
            type: .giphy,
            completionHandler: completionHandler
        )
    }

    func cancelZiphyRequest(withRequestIdentifier requestIdentifier: ZiphyRequestIdentifier) {
        guard let requestIdentifier = requestIdentifier as? ProxyRequest else { return }
        userSession.cancelProxiedRequest(requestIdentifier)
    }

    private func doRequest(
        withPath path: String,
        method: ZMTransportRequestMethod,
        type: ProxiedRequestType,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> ProxyRequest {
        userSession.proxiedRequest(
            path: path,
            method: method,
            type: type,
            callback: completionHandler
        )
    }
}

// MARK: - ProxyRequest + ZiphyRequestIdentifier

extension ProxyRequest: ZiphyRequestIdentifier {}
