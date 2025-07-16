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

import Combine
package import SwiftUI
import WireConversationsAPI
package import WireConversationsImplementation

@MainActor
package class ChannelHistoryViewModel: ObservableObject {
    @Published var channelHistoryOption: ChannelHistoryOption
    @Published var channelHistoryOptionCustom: ChannelHistoryOption.Custom = .init()
    @Published var isLoading: Bool = false
    @Published var isUserPremium: Bool = true
    @Published var channelHistoryAvailableOptions: [ChannelHistoryOption] = []

    public let accentColor: Color
    public let teamsURL: URL
    private let useCase: any ChannelHistoryUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()

    package init(
        historyDepth: Int,
        teamsURL: URL,
        accentColor: Color,
        useCase: any ChannelHistoryUseCaseProtocol
    ) {
        self.channelHistoryOption = switch historyDepth {
        default: .off
        }
        self.useCase = useCase
        self.accentColor = accentColor
        self.teamsURL = teamsURL

        bind()
    }

    func fetchData() async {
        isLoading = true
        do {
            isUserPremium = try await useCase.isUserPremium()
            channelHistoryAvailableOptions = isUserPremium ? [
                .off,
                .oneDay,
                .oneWeek,
                .fourWeeks,
                .unlimited,
                .custom
            ] :
                [
                    .off,
                    .oneDay
                ]
        } catch {}
        isLoading = false
    }

    private func bind() {
        $channelHistoryOption
            .dropFirst()
            .removeDuplicates()
            .sink { [self] channelHistoryOption in
                isLoading = true
                Task {
                    do {
                        try await useCase.updateHistoryDepth(
                            channelHistoryOption: channelHistoryOption,
                            channelHistoryOptionCustom: channelHistoryOptionCustom
                        )
                    } catch {}
                    isLoading = false
                }
            }.store(in: &subscriptions)

    }
}
