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

public import SwiftUI
import WireConversationsAPI

public struct WireConversationChannelCreationForm: View {
    public typealias ViewModel = WireConversationChannelCreationFormViewModel

    @State private var channelName: String

    @ObservedObject private var viewModel: WireConversationChannelCreationFormViewModel

    public init(
        viewModel: WireConversationChannelCreationFormViewModel
    ) {
        self.viewModel = viewModel
        self.channelName = (try? viewModel.channelName.get()) ?? ""
    }

    public var body: some View {
        Form {
            channelNameSection
            channelAccessSection
            // TODO: [WPB-16814] This will be used when implementing the channels history settings.
//            channelHistorySection
            servicesSection
            readReceiptsSection
        }
        .onChange(of: channelName) { newValue in
            viewModel.onChannelNameUpdate(newValue)
        }
    }

    var channelNameSection: some View {
        Section(L10n.Localizable.Conversation.CreationForm.ChannelName.sectionTitle) {
            TextField(
                text: $channelName,
                prompt: Text(L10n.Localizable.Conversation.CreationForm.ChannelName.placeholder),
                label: {
                    Text(L10n.Localizable.Conversation.CreationForm.ChannelName.label)
                }
            )
        }
    }

    var channelAccessSection: some View {
        Section(content: {
            // Channel access is always hard coded to private for now.
            Picker(
                L10n.Localizable.Conversation.CreationForm.Options.channelAccess,
                selection: $viewModel.channelAccess
            ) {
                Text(L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.public)
                    .tag(ViewModel.ChannelAccessOption.public)
                Label(
                    L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.private,
                    systemImage: "lock.fill"
                )
                .tag(ViewModel.ChannelAccessOption.private)
            }
            .disabled(true)
            if case .private = viewModel.channelAccess {
                Picker(
                    L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.invitePolicy,
                    selection: $viewModel.channelInvitePolicy
                ) {
                    Text(L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.InvitePolicy.adminsOnly)
                        .tag(ViewModel.ChannelInvitePolicyOption.admins)
                    Text(
                        L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.InvitePolicy
                            .adminsAndMembers
                    )
                    .tag(ViewModel.ChannelInvitePolicyOption.adminsAndMembers)
                }
            }
        }, header: {
            Text(L10n.Localizable.Conversation.CreationForm.Options.sectionTitle)
        }, footer: {
            Text(L10n.Localizable.Conversation.CreationForm.Options.footer)
        })
    }

    // TODO: [WPB-16814] This will be used when implementing the channels history settings.
//    var channelHistorySection: some View {
//            Section(content: {
//                Picker("Channel history", selection: $channelHistory) {
//                    Text("Off")
//                        .tag(ChannelHistoryOption.off)
//                    Text("1 day")
//                        .tag(ChannelHistoryOption.oneDay)
//                    Text("1 week")
//                        .tag(ChannelHistoryOption.oneWeek)
//                    Text("Unlimited")
//                        .tag(ChannelHistoryOption.unlimited)
//                }
//            }, footer: {
//                Text("Select a period. When participants join this channel, they can follow the history for this time
//                frame.")
//            })
//    }

    var servicesSection: some View {
        Section(content: {
            Toggle(L10n.Localizable.Conversation.CreationForm.Services.toggle, isOn: $viewModel.servicesAllowed)
            Toggle(L10n.Localizable.Conversation.CreationForm.Guests.toggle, isOn: $viewModel.guestsAllowed)
        }, footer: {
            Text(L10n.Localizable.Conversation.CreationForm.Guests.description)
        })
    }

    var readReceiptsSection: some View {
        Section(content: {
            Toggle(L10n.Localizable.Conversation.CreationForm.ReadReceipts.toggle, isOn: $viewModel.readReceiptsEnabled)
        }, footer: {
            Text(L10n.Localizable.Conversation.CreationForm.ReadReceipts.description)
        })
    }
}

#Preview {
    WireConversationChannelCreationForm(
        viewModel: WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
    )
}
