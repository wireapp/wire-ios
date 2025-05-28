//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class NewPushChannelAPIImpl: NewPushChannelAPI, VersionedAPI {

    let pushChannelService: any PushChannelServiceProtocol
    let apiVersion: APIVersion

    init(pushChannelService: any PushChannelServiceProtocol, apiVersion: APIVersion) {
        self.pushChannelService = pushChannelService
        self.apiVersion = apiVersion
    }

    func createPushChannel(clientID: String) async throws -> any NewPushChannelProtocol {
        let path = "\(pathPrefix)/events"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .withQueryItem(name: "client", value: clientID)
            .build()

        return try await pushChannelService.createNewPushChannel(request)
    }

}
