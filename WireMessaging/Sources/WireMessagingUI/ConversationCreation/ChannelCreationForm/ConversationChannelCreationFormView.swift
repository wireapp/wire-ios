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
import WireDesign
import WireMessagingDomain
import WireReusableUIComponents

public struct ConversationChannelCreationForm: View {
    public typealias ViewModel = ConversationChannelCreationFormViewModel

    private typealias Strings = L10n.Localizable.Conversation
    private typealias Labels = L10n.Accessibility.Conversation.CreationForm.ChannelHistory

    @State private var channelName: String
    @Environment(\.openURL) var openURL
    @ObservedObject private var viewModel: ConversationChannelCreationFormViewModel

    public init(
        viewModel: ConversationChannelCreationFormViewModel
    ) {
        self.viewModel = viewModel
        self.channelName = (try? viewModel.channelName.get()) ?? ""
    }

    public var body: some View {
        Form {
            channelNameSection
            channelAccessSection
            if viewModel.isChannelHistoryFeatureEnabled() {
                channelHistorySection
            }
            appsSection
            // TODO: [WPB-16771] Uncomment when read receipts supported on MLS
            //            readReceiptsSection

            if viewModel.isWireDriveEnabled {
                fileManagementSection
            }

        }
        .onChange(of: channelName) { newValue in
            viewModel.onChannelNameUpdate(newValue)
        }
        .overlay {
            ZStack {
                if viewModel.showUpgradeBanner {
                    ZStack {
                        Rectangle()
                            .foregroundColor(Color.black.opacity(0.6))
                            .edgesIgnoringSafeArea(.all)

                        ChannelBannerView(
                            configuration: .init(
                                title: Strings.ChannelHistory.UpgradeBanner.title,
                                message: Strings.ChannelHistory.UpgradeBanner.message,
                                mainButtonTitle: Strings.ChannelHistory.UpgradeBanner.button,
                                mainButtonAction: { openURL(viewModel.teamsURL) },
                                closeButton: .init(
                                    accessibilityLabel: Labels.UpgradeBanner.close,
                                    action: { viewModel.hideUpgradeBanner() }
                                )
                            )
                        ).transition(.opacity)
                    }
                }
            }
            .animation(.easeInOut, value: viewModel.showUpgradeBanner)
        }.animation(.easeInOut, value: viewModel.channelHistoryOption)

    }

    var channelNameSection: some View {
        Section(Strings.CreationForm.ChannelName.sectionTitle) {
            TextField(
                text: $channelName,
                prompt: Text(Strings.CreationForm.ChannelName.placeholder),
                label: {
                    Text(Strings.CreationForm.ChannelName.label)
                }
            )
        }
    }

    var channelAccessSection: some View {
        Section(content: {
            HStack {
                Text(Strings.CreationForm.Options.channelAccess)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                    Text(Strings.CreationForm.Options.ChannelAccess.private)
                        .foregroundColor(.gray)
                }
            }
            if case .private = viewModel.channelAccess {
                Picker(
                    Strings.CreationForm.Options.ChannelAccess.invitePolicy,
                    selection: $viewModel.channelInvitePolicy
                ) {
                    Text(Strings.CreationForm.Options.ChannelAccess.InvitePolicy.adminsOnly)
                        .tag(ViewModel.ChannelInvitePolicyOption.admins)
                    Text(
                        Strings.CreationForm.Options.ChannelAccess.InvitePolicy
                            .adminsAndMembers
                    )
                    .tag(ViewModel.ChannelInvitePolicyOption.adminsAndMembers)
                }
            }
        }, header: {
            Text(Strings.CreationForm.Options.sectionTitle)
        }, footer: {
            Text(Strings.CreationForm.Options.footer)
        })
    }

    var channelHistorySection: some View {
        Section(content: {
            channelHistoryPicker

            if viewModel.showChannelCustomHistoryPickers() {
                withAnimation {
                    channelCustomHistoryPickers
                }
            }

        }, footer: {
            Text(Strings.CreationForm.ChannelHistory.sectionFootnote)
        })
    }

    var channelHistoryPicker: some View {
        Picker(
            Strings.ChannelHistory.Picker.title,
            selection: $viewModel.channelHistoryOption
        ) {
            ForEach(viewModel.channelHistoryAvailableOptions()) { channelHistoryOption in
                Text(channelHistoryOption.title)
                    .tag(channelHistoryOption)
                    .accessibilityLabel(channelHistoryOption.title)
            }
        }
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
                ForEach(ChannelHistoryOption.Custom.Unit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.wheel)
        }
    }

    var appsSection: some View {
        Section(content: {
            Toggle(Strings.CreationForm.Apps.toggle, isOn: $viewModel.appsAllowed)
            Toggle(Strings.CreationForm.Guests.toggle, isOn: $viewModel.guestsAllowed)
        }, footer: {
            Text(Strings.CreationForm.Guests.description)
        })
    }

    var readReceiptsSection: some View {
        Section(content: {
            Toggle(Strings.CreationForm.ReadReceipts.toggle, isOn: $viewModel.readReceiptsEnabled)
        }, footer: {
            Text(Strings.CreationForm.ReadReceipts.description)
        })
    }

    var fileManagementSection: some View {
        Section(content: {
            Toggle(Strings.CreationForm.WireCells.toggle + " (Cells beta)", isOn: $viewModel.fileManagementEnabled)
        }, footer: {
            Text(Strings.CreationForm.WireCells.description)
            // Text(" [\(Strings.CreationForm.WireCells.learnMore)](https://wire.com)") // TODO: [WPB-20191] URL to be
            // defined, uncomment when we have the URL
        })
    }
}

#Preview {
    ConversationChannelCreationForm(
        viewModel: ConversationChannelCreationFormViewModel(
            channelName: "",
            isUserPremium: false,
            isWireDriveEnabled: true,
            teamsURL: URL(string: "https://wire.com")!
        ) { _ in }
    )
}
