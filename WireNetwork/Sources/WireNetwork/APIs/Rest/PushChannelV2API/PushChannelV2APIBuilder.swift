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
import Foundation

public struct PushChannelV2APIBuilder {

    private let pushChannelService: PushChannelService

    /// Create a new builder.
    ///
    /// - Parameter pushChannelService: A push channel service to execute requests.
    ///
    public init(pushChannelService: PushChannelService) {
        self.pushChannelService = pushChannelService
    }

    /// Make a `PushChannelAPI`.
    ///
    /// - Returns: A `PushChannelAPI`.

    public func makeAPI(for apiVersion: APIVersion) -> any PushChannelV2API {
        switch apiVersion {

        case .v0:
            PushChannelV2APIV0(pushChannelService: pushChannelService)
        case .v1:
            PushChannelV2APIV1(pushChannelService: pushChannelService)
        case .v2:
            PushChannelV2APIV2(pushChannelService: pushChannelService)
        case .v3:
            PushChannelV2APIV3(pushChannelService: pushChannelService)
        case .v4:
            PushChannelV2APIV4(pushChannelService: pushChannelService)
        case .v5:
            PushChannelV2APIV5(pushChannelService: pushChannelService)
        case .v6:
            PushChannelV2APIV6(pushChannelService: pushChannelService)
        case .v7:
            PushChannelV2APIV7(pushChannelService: pushChannelService)
        case .v8:
            PushChannelV2APIV8(pushChannelService: pushChannelService)
        case .v9:
            PushChannelV2APIV9(pushChannelService: pushChannelService)
        case .v10:
            PushChannelV2APIV10(pushChannelService: pushChannelService)
        case .v11:
            PushChannelV2APIV11(pushChannelService: pushChannelService)
        case .v12:
            PushChannelV2APIV12(pushChannelService: pushChannelService)
        case .v13:
            PushChannelV2APIV13(pushChannelService: pushChannelService)
        case .v14:
            PushChannelV2APIV14(pushChannelService: pushChannelService)
        }
    }

}
