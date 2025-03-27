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

import SwiftUI

package struct ChannelAccessView: View {
    
    @ObservedObject var viewModel: ChannelAccessViewModel
    
    package init(viewModel: ChannelAccessViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Access")) {
                    accessOption(title: "Public", level: .public)
                        .disabled(viewModel.isPublicDisabled)
                        .opacity(viewModel.isPublicDisabled ? 0.4 : 1.0)

                    accessOption(title: "Private", level: .private)
                }

                if viewModel.showParticipantPermissions {
                    Section(header: Text("Add Participants")) {
                        permissionOption(title: "Admins", permission: .admins)
                        permissionOption(title: "Admins and members", permission: .adminsAndMembers)
                    }

                    Text("Select who can add participants to a private channel")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Access")
            .alert(isPresented: $viewModel.showPrivateAccessConfirmation) {
                Alert(
                    title: Text("Channel access"),
                    message: Text("""
Changing the channel access to private will have the following implications:

• Team members can not join the channel themselves anymore.
• New members can only be added by channel admins or other members, depending on the “Add participants” setting.
• The channel access can not be turned back to public anymore.

Do you want to change channel access to private?
"""),
                    primaryButton: .default(Text("Change")) {
                        viewModel.confirmPrivateAccessChange()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func accessOption(title: String, level: ChannelAccessLevel) -> some View {
        HStack {
            Text(title)
            Spacer()
            if viewModel.settings.accessLevel == level {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectAccessLevel(level)
        }
    }

    private func permissionOption(title: String, permission: ParticipantPermission) -> some View {
        HStack {
            Text(title)
            Spacer()
            if viewModel.settings.participantPermission == permission {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.selectParticipantPermission(permission)
        }
    }
}
