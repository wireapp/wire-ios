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
                    Text("Show older messages?")
                        .wireTextStyle(.buttonSmall)
                        .foregroundStyle(Color.white)
                        .bold()
                    
                    Spacer()
                    
                    CloseButton(
                        action: {
                            viewModel.hideUpgradeBanner()
                        },
                        foregroundColor: SemanticColors.Label.textWhite,
                        accessibilityLabel: String(
                            localized: "",
                            table: "Accessibility",
                            bundle: .module
                        )
                    )
                }
                
                Text("Upgrade to a paid plan to offer channel members the whole history.")
                    .foregroundStyle(.white)
                
                Link(
                    "Upgrade now",
                    destination: URL(string: "https://teams.wire.com/billing/)")!
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
            .roundedBorderAndBackground(
                backgroundColor: ColorTheme.Base.onHighlight.color,
                borderColor: ColorTheme.Base.onHighlight.color,
                borderWidth: 1,
                cornerRadius: 10,
                padding: 15
            )
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

struct NavigationControllerAccessor: UIViewControllerRepresentable {
    var callback: (UINavigationController?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        ViewController(callback: callback)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private class ViewController: UIViewController {
        let callback: (UINavigationController?) -> Void

        init(callback: @escaping (UINavigationController?) -> Void) {
            self.callback = callback
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            callback(self.navigationController)
        }
    }
}


#Preview {
    WireConversationChannelCreationForm(
        viewModel: WireConversationChannelCreationFormViewModel(channelName: "") { _ in }
    )
}
