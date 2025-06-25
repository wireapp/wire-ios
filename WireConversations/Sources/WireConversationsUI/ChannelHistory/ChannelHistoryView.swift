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
import WireConversationsAPI
import WireConversationsImplementation
import WireConversationsImplementationSupport
import WireDesign

package struct ChannelHistoryView: View {
    @ObservedObject var viewModel: ChannelHistoryViewModel
    @State private var rotationAngle: Double = 0
    @State private var isExpanded: Bool = false

    package init(viewModel: ChannelHistoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(
                    footer: Text(L10n.Localizable.Conversation.UpdateHistory.ChannelHistory.sectionFootnote)
                        .font(.footnote)
                        .foregroundColor(ColorTheme.Base.secondaryText.color)
                ) {
                    ForEach(ChannelHistoryOption.allCases, id: \.self) { channelHistoryOption in
                        HStack {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    rotationAngle = channelHistoryOption == .custom ? 90 : 0
                                }

                                isExpanded = channelHistoryOption == .custom
                                viewModel.channelHistoryOption = channelHistoryOption
                            } label: {
                                Text(channelHistoryOption.title)
                                    .foregroundStyle(ColorTheme.Backgrounds.onSurface.color)
                            }

                            Spacer()

                            if viewModel.channelHistoryOption == channelHistoryOption {
                                Checkmark(accentColor: viewModel.accentColor)
                            }

                            if channelHistoryOption == .custom {
                                Image("wire_conversations_chevron_right", bundle: .resources)
                                    .renderingMode(.template)
                                    .padding(.leading, 8)
                                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                                    .rotationEffect(.degrees(rotationAngle))
                            }
                        }
                    }

                    if viewModel.channelHistoryOption == .custom {
                        channelCustomHistoryPickers
                    }

                }
                .background(.clear)
            }
            .background(ColorTheme.Backgrounds.background.color)
            .animation(.easeInOut(duration: 2), value: isExpanded)
        }
        .scrollContentBackground(.hidden)
        .background(ColorTheme.Backgrounds.background.color.ignoresSafeArea())
    }

    var channelCustomHistoryPickers: some View {
        HStack {
            Picker("Number", selection: $viewModel.channelHistoryOptionCustom.value) {
                ForEach(1 ... 99, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)

            Picker("Unit", selection: $viewModel.channelHistoryOptionCustom.unit) {
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
    var title: String {
        switch self {
        case .off:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.Picker.off
        case .oneDay:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.Picker.oneDay
        case .oneWeek:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.Picker.oneWeek
        case .fourWeeks:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.Picker.fourWeeks
        case .unlimited:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.Picker.unlimited
        case .custom:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.Picker.custom
        }
    }
}

extension ChannelHistoryOption.Custom.Unit {
    var title: String {
        switch self {
        case .days:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.CustomPicker.days
        case .week:
            L10n.Localizable.Conversation.CreationForm.ChannelHistory.CustomPicker.weeks
        }
    }
}

struct ChannelHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                ChannelHistoryView(viewModel: ChannelHistoryViewModel(
                    historyDepth: 10_000,
                    accentColor: .blue,
                    useCase: ChannelHistoryUseCase(
                        repository: MockChannelRepositoryProtocol()
                    )
                ))

            }
        }

    }
}
