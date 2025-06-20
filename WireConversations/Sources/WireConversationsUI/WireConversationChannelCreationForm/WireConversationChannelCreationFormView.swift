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
import WireDesign
import WireConversationsAPI
import WireReusableUIComponents

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
            .overlay {
                ZStack {
                    if viewModel.showUpgradeBanner {
                        channelUpgradeBanner
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut, value: viewModel.showUpgradeBanner)
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
    
    var channelUpgradeBanner: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.black.opacity(0.6))
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text(L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner.title)
                        .wireTextStyle(.buttonSmall)
                        .foregroundStyle(Color.white)
                        .bold()
                    
                    Spacer()
                    
                    CloseButton(
                        action: { viewModel.hideUpgradeBanner() },
                        foregroundColor: SemanticColors.Label.textWhite,
                        accessibilityLabel: String(
                            localized: "",
                            table: "Accessibility",
                            bundle: .module
                        )
                    )
                }
                
                HStack {
                    Text(L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner.message)
                        .foregroundStyle(.white)
                    
                    Spacer()
                        .frame(width: 80)
                }
                
                Link(
                    L10n.Localizable.Conversation.CreationForm.ChannelHistory.UpgradeBanner.button,
                    destination: viewModel.upgradeBannerURL()
                )
                .lineLimit(1)
                .padding(8)
                .background(Color.white.opacity(0.2))
                .foregroundStyle(Color.white)
                .wireTextStyle(.buttonSmall)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.black)
                }
                .clipShape(.rect(cornerRadius: 12))
                
            }
            .padding(.all, 15)
            .background(alignment: .top) {
                Image("wire_upgrade_banner", bundle: .resources)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .cornerRadius(10)
            .clipped()
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing], 30)
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
                VStack {
                    channelHistoryPicker
                    
                    ZStack {
                        if viewModel.showChannelCustomHistoryPickers() {
                            channelCustomHistoryPicker
                                .transition(.opacity)
                        }
                    }.animation(.smooth, value: viewModel.channelHistoryOption)
                }
                
            }, footer: {
                Text("Select a period. When participants join this channel, they can follow the history for this time")
            })
    }
    
    var channelHistoryPicker: some View {
        Picker("Channel history", selection: $viewModel.channelHistoryOption) {
            ForEach(viewModel.channelHistoryAvailableOptions(), id: \.self) { channelHistoryOption in
                Text(channelHistoryOption.title)
                    .tag(channelHistoryOption)

            }
        }
    }
    
    var channelCustomHistoryPicker: some View {
        HStack {
            Picker("Number", selection: $viewModel.channelHistoryOptionCustom.value) {
                ForEach(1...99, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)

            Picker("Unit", selection: $viewModel.channelHistoryOptionCustom.unit) {
                ForEach(ViewModel.ChannelHistoryOption.Custom.Unit.allCases, id: \.self) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.wheel)
        }
        .padding()
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
