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

package import SwiftUI
import WireDesign
import WireMessagingAPI
import WireMessagingImplementation
import WireMessagingImplementationSupport

package struct ChannelHistoryView: View {
    @ObservedObject var viewModel: ChannelHistoryViewModel
    @Environment(\.openURL) var openURL
    @State private var rotationAngle: Double = 0
    @State private var isExpanded: Bool = false

    typealias ChannelHistory = L10n.Localizable.Conversation.ChannelHistory

    package init(viewModel: ChannelHistoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            Form {
                channelHistorySection
                    .background(.clear)

                if !viewModel.isUserPremium {
                    nonPremiumBannerSection
                }
            }
            .background(ColorTheme.Backgrounds.background.color)
            .animation(.easeInOut(duration: 2), value: isExpanded)
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color.ignoresSafeArea())
        .task {
            await viewModel.fetchData()
        }
    }

    // MARK: - Channel History Section

    private var channelHistorySection: some View {
        Section(
            footer: Text(ChannelHistory.Share.sectionFootnote)
                .font(.footnote)
                .foregroundColor(ColorTheme.Base.secondaryText.color)
        ) {
            ForEach(viewModel.channelHistoryAvailableOptions, id: \.self) { option in
                channelHistoryRow(for: option)
            }

            if viewModel.channelHistoryOption == .custom {
                channelCustomHistoryPickers
            }
        }
    }

    // MARK: - Row for Channel History Option

    @ViewBuilder
    private func channelHistoryRow(for option: ChannelHistoryOption) -> some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationAngle = option == .custom ? 90 : 0
                }

                isExpanded = option == .custom
                viewModel.channelHistoryOption = option
            } label: {
                Text(option.title)
                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
            }

            Spacer()

            if viewModel.channelHistoryOption == option {
                Checkmark(accentColor: viewModel.accentColor)
            }

            if option == .custom {
                Image("wire_conversations_chevron_right", bundle: .resources)
                    .renderingMode(.template)
                    .padding(.leading, 8)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .rotationEffect(.degrees(rotationAngle))
            }
        }
    }

    // MARK: - Non-Premium Banner Section

    private var nonPremiumBannerSection: some View {
        Section {
            WireChannelBannerView(
                configuration: .init(
                    title: ChannelHistory.UpgradeBanner.title,
                    message: ChannelHistory.UpgradeBanner.message,
                    mainButtonTitle: ChannelHistory.UpgradeBanner.button,
                    mainButtonAction: { openURL(viewModel.teamsURL) },
                    closeButton: .none
                )
            )
        }
        .listRowBackground(Color.clear)
    }

    var channelCustomHistoryPickers: some View {
        HStack {
            Picker("", selection: $viewModel.channelHistoryOptionCustom.value) {
                ForEach(1 ... 99, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)

            Picker("", selection: $viewModel.channelHistoryOptionCustom.unit) {
                ForEach(ChannelHistoryOption.Custom.Unit.allCases, id: \.self) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.wheel)
        }
    }

    struct Checkmark: View {
        let accentColor: Color

        var body: some View {
            Image("Check", bundle: .resources)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 22)
                .foregroundColor(accentColor)
        }
    }
}

extension ChannelHistoryOption {
    typealias ChannelHistory = L10n.Localizable.Conversation.ChannelHistory

    var title: String {
        switch self {
        case .off:
            ChannelHistory.Picker.off
        case .oneDay:
            ChannelHistory.Picker.oneDay
        case .oneWeek:
            ChannelHistory.Picker.oneWeek
        case .fourWeeks:
            ChannelHistory.Picker.fourWeeks
        case .unlimited:
            ChannelHistory.Picker.unlimited
        case .custom:
            ChannelHistory.Picker.custom
        }
    }
}

extension ChannelHistoryOption.Custom.Unit {
    typealias ChannelHistory = L10n.Localizable.Conversation.ChannelHistory

    var title: String {
        switch self {
        case .days:
            ChannelHistory.CustomPicker.days
        case .week:
            ChannelHistory.CustomPicker.weeks
        }
    }
}

struct ChannelHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                ChannelHistoryView(viewModel: ChannelHistoryViewModel(
                    historyDepth: 10_000,
                    teamsURL: URL(string: "https://google.com")!,
                    accentColor: .blue,
                    useCase: ChannelHistoryUseCase(
                        repository: channelRepository()
                    )
                ))

            }
        }

    }

    static func channelRepository() -> MockChannelRepositoryProtocol {
        let channelRepository = MockChannelRepositoryProtocol()
        channelRepository.updateHistoryDepth_MockMethod = { _ in }
        channelRepository.isConferenceCallingFeatureEnabled_MockValue = true
        return channelRepository
    }
}
