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
import WireFoundation

public struct UpdateChannelHistoryDepthUseCase: UpdateChannelHistoryDepthUseCaseProtocol {
    public let repository: any ChannelRepositoryProtocol

    public init(
        repository: any ChannelRepositoryProtocol
    ) {
        self.repository = repository
    }

    public func invoke(
        channelHistoryOption: ChannelHistoryOption,
        channelHistoryOptionCustom: ChannelHistoryOption.Custom
    ) async throws {
        let historyDepth = getHistoryDepth(
            channelHistoryOption: channelHistoryOption,
            channelHistoryOptionCustom: channelHistoryOptionCustom
        )

        try await repository.updateHistoryDepth(
            historyDepth
        )
    }

    private func getHistoryDepth(
        channelHistoryOption: ChannelHistoryOption,
        channelHistoryOptionCustom: ChannelHistoryOption.Custom
    ) -> String? {
        switch channelHistoryOption {
        case .off:
            .none
        case .oneDay:
            "One day"
        case .oneWeek:
            "One week"
        case .fourWeeks:
            "Four weeks"
        case .unlimited:
            "Unlimited"
        case .custom:
            "\(channelHistoryOptionCustom.value) \(channelHistoryOptionCustom.unit == .days ? "days" : "weeks")"
        }
    }
}
