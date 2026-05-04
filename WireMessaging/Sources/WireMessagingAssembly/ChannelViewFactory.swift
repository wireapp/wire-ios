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

public import SwiftUI
public import WireMessagingDomain
import UIKit
import WireMessagingUI

public class ChannelViewFactory {
    @MainActor
    public static func makeChannelAccessView(
        permission: ChannelAccessLevelPermission?,
        accentColor: Color,
        repository: any ChannelRepositoryProtocol
    ) -> UIViewController {
        let useCase = ChannelAccessUseCase(permission: permission, repository: repository)
        let viewModel = ChannelAccessViewModel(
            accentColor: accentColor, useCase: useCase
        )

        return ChannelAccessHostingController(viewModel: viewModel)
    }

    @MainActor
    public static func makeChannelHistoryView(
        historyDepth: String?,
        accentColor: Color,
        teamsURL: URL,
        repository: any ChannelRepositoryProtocol
    ) -> UIViewController {
        let useCase = ChannelHistoryUseCase(
            updateChannelHistoryDepthUseCase: UpdateChannelHistoryDepthUseCase(repository: repository),
            fetchIsEnterpriseUserUseCase: FetchIsEnterpriseUserUseCase(repository: repository)
        )

        let viewModel = ChannelHistoryViewModel(
            historyDepth: historyDepth,
            teamsURL: teamsURL,
            accentColor: accentColor,
            useCase: useCase
        )

        return ChannelHistoryHostingController(viewModel: viewModel)
    }
}
