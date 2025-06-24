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

    let apiVersion: APIVersion
    let apiService: APIService
    let pushChannelService: PushChannelService

    public func accountsAPI() -> some AccountsAPI {
        switch apiVersion {
        case .v0:
            AccountsAPIV0(apiService: apiService)
        case .v1:
            AccountsAPIV1(apiService: apiService)
        case .v2:
            AccountsAPIV2(apiService: apiService)
        case .v3:
            AccountsAPIV3(apiService: apiService)
        case .v4:
            AccountsAPIV4(apiService: apiService)
        case .v5:
            AccountsAPIV5(apiService: apiService)
        case .v6:
            AccountsAPIV6(apiService: apiService)
        case .v7:
            AccountsAPIV7(apiService: apiService)
        case .v8:
            AccountsAPIV8(apiService: apiService)
        }
    }

    public func connectionsAPI() -> some ConnectionsAPI {
        switch apiVersion {
        case .v0:
            ConnectionsAPIV0(apiService: apiService)
        case .v1:
            ConnectionsAPIV1(apiService: apiService)
        case .v2:
            ConnectionsAPIV2(apiService: apiService)
        case .v3:
            ConnectionsAPIV3(apiService: apiService)
        case .v4:
            ConnectionsAPIV4(apiService: apiService)
        case .v5:
            ConnectionsAPIV5(apiService: apiService)
        case .v6:
            ConnectionsAPIV6(apiService: apiService)
        case .v7:
            ConnectionsAPIV7(apiService: apiService)
        case .v8:
            ConnectionsAPIV8(apiService: apiService)
        }
    }

    public func conversationsAPI() -> some ConversationsAPI {
        switch apiVersion {
        case .v0:
            ConversationsAPIV0(apiService: apiService)
        case .v1:
            ConversationsAPIV1(apiService: apiService)
        case .v2:
            ConversationsAPIV2(apiService: apiService)
        case .v3:
            ConversationsAPIV3(apiService: apiService)
        case .v4:
            ConversationsAPIV4(apiService: apiService)
        case .v5:
            ConversationsAPIV5(apiService: apiService)
        case .v6:
            ConversationsAPIV6(apiService: apiService)
        case .v7:
            ConversationsAPIV7(apiService: apiService)
        case .v8:
            ConversationsAPIV8(apiService: apiService)
        }
    }

    public func featureConfigsAPI() -> some FeatureConfigsAPI {
        switch apiVersion {
        case .v0:
            FeatureConfigsAPIV0(apiService: apiService)
        case .v1:
            FeatureConfigsAPIV1(apiService: apiService)
        case .v2:
            FeatureConfigsAPIV2(apiService: apiService)
        case .v3:
            FeatureConfigsAPIV3(apiService: apiService)
        case .v4:
            FeatureConfigsAPIV4(apiService: apiService)
        case .v5:
            FeatureConfigsAPIV5(apiService: apiService)
        case .v6:
            FeatureConfigsAPIV6(apiService: apiService)
        case .v7:
            FeatureConfigsAPIV7(apiService: apiService)
        case .v8:
            FeatureConfigsAPIV8(apiService: apiService)
        }
    }

    public func mlsAPI() -> some MLSAPI {
        switch apiVersion {
        case .v0:
            MLSAPIV0(apiService: apiService)
        case .v1:
            MLSAPIV1(apiService: apiService)
        case .v2:
            MLSAPIV2(apiService: apiService)
        case .v3:
            MLSAPIV3(apiService: apiService)
        case .v4:
            MLSAPIV4(apiService: apiService)
        case .v5:
            MLSAPIV5(apiService: apiService)
        case .v6:
            MLSAPIV6(apiService: apiService)
        case .v7:
            MLSAPIV7(apiService: apiService)
        case .v8:
            MLSAPIV8(apiService: apiService)
        }
    }

    public func pushChannelAPI() -> some PushChannelAPI {
        PushChannelAPIImpl(pushChannelService: pushChannelService)
    }

    public func pushChannelV2API() -> some PushChannelV2API {
        PushChannelV2APIImpl(
            pushChannelService: pushChannelService,
            apiVersion: apiVersion
        )
    }

    public func selfUserAPI() -> some SelfUserAPI {
        switch apiVersion {
        case .v0:
            SelfUserAPIV0(apiService: apiService)
        case .v1:
            SelfUserAPIV1(apiService: apiService)
        case .v2:
            SelfUserAPIV2(apiService: apiService)
        case .v3:
            SelfUserAPIV3(apiService: apiService)
        case .v4:
            SelfUserAPIV4(apiService: apiService)
        case .v5:
            SelfUserAPIV5(apiService: apiService)
        case .v6:
            SelfUserAPIV6(apiService: apiService)
        case .v7:
            SelfUserAPIV7(apiService: apiService)
        case .v8:
            SelfUserAPIV8(apiService: apiService)
        }
    }

    public func teamsAPI() -> some TeamsAPI {
        switch apiVersion {
        case .v0:
            TeamsAPIV0(apiService: apiService)
        case .v1:
            TeamsAPIV1(apiService: apiService)
        case .v2:
            TeamsAPIV2(apiService: apiService)
        case .v3:
            TeamsAPIV3(apiService: apiService)
        case .v4:
            TeamsAPIV4(apiService: apiService)
        case .v5:
            TeamsAPIV5(apiService: apiService)
        case .v6:
            TeamsAPIV6(apiService: apiService)
        case .v7:
            TeamsAPIV7(apiService: apiService)
        case .v8:
            TeamsAPIV8(apiService: apiService)
        }
    }

    public func updateEventsAPI() -> some UpdateEventsAPI {
        switch apiVersion {
        case .v0:
            UpdateEventsAPIV0(apiService: apiService)
        case .v1:
            UpdateEventsAPIV1(apiService: apiService)
        case .v2:
            UpdateEventsAPIV2(apiService: apiService)
        case .v3:
            UpdateEventsAPIV3(apiService: apiService)
        case .v4:
            UpdateEventsAPIV4(apiService: apiService)
        case .v5:
            UpdateEventsAPIV5(apiService: apiService)
        case .v6:
            UpdateEventsAPIV6(apiService: apiService)
        case .v7:
            UpdateEventsAPIV7(apiService: apiService)
        case .v8:
            UpdateEventsAPIV8(apiService: apiService)
        }
    }

    public func usersAPI() -> some UsersAPI {
        switch apiVersion {
        case .v0:
            UsersAPIV0(apiService: apiService)
        case .v1:
            UsersAPIV1(apiService: apiService)
        case .v2:
            UsersAPIV2(apiService: apiService)
        case .v3:
            UsersAPIV3(apiService: apiService)
        case .v4:
            UsersAPIV4(apiService: apiService)
        case .v5:
            UsersAPIV5(apiService: apiService)
        case .v6:
            UsersAPIV6(apiService: apiService)
        case .v7:
            UsersAPIV7(apiService: apiService)
        case .v8:
            UsersAPIV8(apiService: apiService)
        }
    }

    public func userClientsAPI() -> some UserClientsAPI {
        switch apiVersion {
        case .v0:
            UserClientsAPIV0(apiService: apiService)
        case .v1:
            UserClientsAPIV1(apiService: apiService)
        case .v2:
            UserClientsAPIV2(apiService: apiService)
        case .v3:
            UserClientsAPIV3(apiService: apiService)
        case .v4:
            UserClientsAPIV4(apiService: apiService)
        case .v5:
            UserClientsAPIV5(apiService: apiService)
        case .v6:
            UserClientsAPIV6(apiService: apiService)
        case .v7:
            UserClientsAPIV7(apiService: apiService)
        case .v8:
            UserClientsAPIV8(apiService: apiService)
        }
    }

    public func userPropertiesAPI() -> some UserPropertiesAPI {
        switch apiVersion {
        case .v0:
            UserPropertiesAPIV0(apiService: apiService)
        case .v1:
            UserPropertiesAPIV1(apiService: apiService)
        case .v2:
            UserPropertiesAPIV2(apiService: apiService)
        case .v3:
            UserPropertiesAPIV3(apiService: apiService)
        case .v4:
            UserPropertiesAPIV4(apiService: apiService)
        case .v5:
            UserPropertiesAPIV5(apiService: apiService)
        case .v6:
            UserPropertiesAPIV6(apiService: apiService)
        case .v7:
            UserPropertiesAPIV7(apiService: apiService)
        case .v8:
            UserPropertiesAPIV8(apiService: apiService)
        }
    }

}
