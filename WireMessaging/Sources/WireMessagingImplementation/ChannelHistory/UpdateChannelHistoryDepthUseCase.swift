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

import WireFoundation
public import WireMessagingAPI
import Foundation

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
        let historyDepth = computeHistoryDepth(
            channelHistoryOption: channelHistoryOption,
            channelHistoryOptionCustom: channelHistoryOptionCustom
        )

        try await repository.updateHistoryDepth(
            historyDepth
        )
    }

    private func computeHistoryDepth(
        channelHistoryOption: ChannelHistoryOption,
        channelHistoryOptionCustom: ChannelHistoryOption.Custom
    ) -> Int? {
        let historyDepth: TimeInterval? = switch channelHistoryOption {
        case .off:
            nil
        case .oneDay:
            TimeInterval.oneDay
        case .oneWeek:
            TimeInterval.oneWeek
        case .fourWeeks:
            TimeInterval.fourWeeks
        case .unlimited:
            TimeInterval.oneYearFromNow
        case .custom:
            computeHistoryCustomDepth(channelHistoryOptionCustom: channelHistoryOptionCustom)
        }

        return historyDepth != nil ? Int(historyDepth!) : nil
    }

    private func computeHistoryCustomDepth(
        channelHistoryOptionCustom: ChannelHistoryOption.Custom
    ) -> TimeInterval {
        let value = TimeInterval(channelHistoryOptionCustom.value)
        let oneDay = TimeInterval.oneDay

        switch channelHistoryOptionCustom.unit {
        case .days:
            return value * oneDay
        case .week:
            return value * 7 * oneDay
        }
    }
}
