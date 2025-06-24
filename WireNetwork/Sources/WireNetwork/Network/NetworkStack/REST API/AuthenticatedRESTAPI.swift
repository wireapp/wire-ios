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

public struct AuthenticatedRESTAPI {

    public let apiVersion: APIVersion
    let apiService: APIService
    let pushChannelService: PushChannelService

    public func accountsAPI() -> some AccountsAPI {
        AccountsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func connectionsAPI() -> some ConnectionsAPI {
        ConnectionsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func conversationsAPI() -> some ConversationsAPI {
        ConversationsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func featureConfigsAPI() -> some FeatureConfigsAPI {
        FeatureConfigsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func mlsAPI() -> some MLSAPI {
        MLSAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func pushChannelAPI() -> some PushChannelAPI {
        PushChannelAPIBuilder(pushChannelService: pushChannelService)
            .makeAPI()
    }

    public func pushChannelV2API() -> some PushChannelV2API {
        PushChannelV2APIBuilder(pushChannelService: pushChannelService)
            .makeAPI(for: apiVersion)
    }

    public func selfUserAPI() -> some SelfUserAPI {
        SelfUserAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func teamsAPI() -> some TeamsAPI {
        TeamsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func updateEventsAPI() -> some UpdateEventsAPI {
        UpdateEventsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func usersAPI() -> some UsersAPI {
        UsersAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func userClientsAPI() -> some UserClientsAPI {
        UserClientsAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

    public func userPropertiesAPI() -> some UserPropertiesAPI {
        UserPropertiesAPIBuilder(apiService: apiService)
            .makeAPI(for: apiVersion)
    }

}
