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
package import WireConversationsAPI

package struct WireConversationChannelCreationForm: View {

    // TODO: [WPB-16814] This will be used when implementing the channels history settings.
//    enum ChannelHistoryOption: Equatable, Hashable {
//        case off
//        case oneDay
//        case oneWeek
//        case unlimited
//        case custom(WireConversationChannelHistorySetting.LimitedHistoryValue)
//    }

    package enum ChannelAccessOption: Equatable, Hashable {
        case `public`
        case `private`

        fileprivate func wireChannelAccess(invitePolicy: ChannelInvitePolicyOption) -> WireConversationChannelAccess {
            switch self {
            case .public:
                .public
            case .private:
                .private(invitePolicy.wireChannelInvitePolicy)
            }
        }
    }

    package enum ChannelInvitePolicyOption: Equatable, Hashable {
        case admins
        case adminsAndMembers

        fileprivate var wireChannelInvitePolicy: WireConversationChannelAccess.PrivateChannelInvitePolicy {
            switch self {
            case .admins:
                .admins
            case .adminsAndMembers:
                .adminsAndMembers
            }
        }
    }

    @State var channelName: String
    @State var channelAccess: ChannelAccessOption
    @State var channelInvitePolicy: ChannelInvitePolicyOption
    // TODO: [WPB-16814] This will be used when implementing the channels history settings.
//    @State var channelHistory: ChannelHistoryOption
    @State var servicesAllowed: Bool
    @State var guestsAllowed: Bool
    @State var readReceiptsEnabled: Bool

    @State var isFormValid: Bool

    private let onFormValidityUpdate: @Sendable (_ isValid: Bool) -> Void

    package init(
        channelName: String = "",
        channelAccess: ChannelAccessOption = .public,
        // TODO: [WPB-16814] This will be used when implementing the channels history settings.
//        channelHistory: ChannelHistoryOption = .oneDay,
        channelInvitePolicy: ChannelInvitePolicyOption = .admins,
        servicesAllowed: Bool = true,
        guestsAllowed: Bool = true,
        readReceiptsEnabled: Bool = true,
        onFormValidityUpdate: @escaping @Sendable (_ isValid: Bool) -> Void
    ) {
        self.channelName = channelName
        self.channelAccess = channelAccess
//        self.channelHistory = channelHistory
        self.channelInvitePolicy = channelInvitePolicy
        self.servicesAllowed = servicesAllowed
        self.guestsAllowed = guestsAllowed
        self.readReceiptsEnabled = readReceiptsEnabled

        self.onFormValidityUpdate = onFormValidityUpdate

        self.isFormValid = Self.validateForm(channelName: channelName)
    }

    package var body: some View {
        Form {
            channelNameSection
            channelAccessSection
            // TODO: [WPB-16814] This will be used when implementing the channels history settings.
//            channelHistorySection
            servicesSection
            readReceiptsSection
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
            Picker(L10n.Localizable.Conversation.CreationForm.Options.channelAccess, selection: $channelAccess) {
                Text(L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.public)
                    .tag(ChannelAccessOption.public)
                Label(
                    L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.private,
                    systemImage: "lock.fill"
                )
                .tag(ChannelAccessOption.private)
            }
            if case .private = channelAccess {
                Picker(
                    L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.invitePolicy,
                    selection: $channelInvitePolicy
                ) {
                    Text(L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.InvitePolicy.adminsOnly)
                        .tag(ChannelInvitePolicyOption.admins)
                    Text(
                        L10n.Localizable.Conversation.CreationForm.Options.ChannelAccess.InvitePolicy
                            .adminsAndMembers
                    )
                    .tag(ChannelInvitePolicyOption.adminsAndMembers)
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
            Toggle(L10n.Localizable.Conversation.CreationForm.Services.toggle, isOn: $servicesAllowed)
            Toggle(L10n.Localizable.Conversation.CreationForm.Guests.toggle, isOn: $guestsAllowed)
        }, footer: {
            Text(L10n.Localizable.Conversation.CreationForm.Guests.description)
        })
    }

    var readReceiptsSection: some View {
        Section(content: {
            Toggle(L10n.Localizable.Conversation.CreationForm.ReadReceipts.toggle, isOn: $readReceiptsEnabled)
        }, footer: {
            Text(L10n.Localizable.Conversation.CreationForm.ReadReceipts.description)
        })
    }

    func updateChannelName(_ value: String) {
        channelName = value
        updateIsFormValid(Self.validateForm(channelName: value))
    }

    func updateIsFormValid(_ value: Bool) {
        isFormValid = value
        onFormValidityUpdate(value)
    }

    public var channelCreationSettings: WireConversationChannelCreationSettings {
        WireConversationChannelCreationSettings(
            channelName: channelName,
            channelAccess: channelAccess.wireChannelAccess(
                invitePolicy: channelInvitePolicy
            ),
            servicesAllowed: servicesAllowed,
            guestsAllowed: guestsAllowed,
            readReceiptsEnabled: readReceiptsEnabled
        )
    }

    private static func validateForm(
        channelName: String
    ) -> Bool {
        !channelName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    WireConversationChannelCreationForm(
        onFormValidityUpdate: { _ in }
    )
}
