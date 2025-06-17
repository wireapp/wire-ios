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
            channelHistorySection
            servicesSection
            // TODO: [WPB-16771] Uncomment when read receipts supported on MLS
//            readReceiptsSection
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
            HStack {
                Text(L10n.Localizable.Conversation.CreationForm.Options.channelAccess)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                    Text(L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.private)
                        .foregroundColor(.gray)
                }
            }
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

    var channelHistorySection: some View {
            Section(content: {
                Picker("Channel history", selection: $viewModel.channelHistoryOption) {
                    Text("Off")
                        .tag(WireConversationChannelCreationFormViewModel.ChannelHistoryOption.off)
                    Text("1 day")
                        .tag(WireConversationChannelCreationFormViewModel.ChannelHistoryOption.oneDay)
                    
                    if viewModel.isPremium() {
                        Text("1 week")
                            .tag(WireConversationChannelCreationFormViewModel.ChannelHistoryOption.oneWeek)
                        Text("4 weeks")
                            .tag(WireConversationChannelCreationFormViewModel.ChannelHistoryOption.fourWeeks)
                        Text("Unlimited")
                            .tag(WireConversationChannelCreationFormViewModel.ChannelHistoryOption.unlimited)
                    }
                    
                    HStack {
                        Text("Custom")

                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                        
                    }.tag(WireConversationChannelCreationFormViewModel.ChannelHistoryOption.custom)
                    .padding(.horizontal)

                }
            }, footer: {
                Text("Select a period. When participants join this channel, they can follow the history for this time")
            })
    }

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
