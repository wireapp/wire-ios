//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

struct ConfirmationView: View {

    enum Action {
        case goBack
        case `continue`
    }

    @State var password: String = ""
    @State var migrationConfirmed: Bool = false
    @State var termsAccepted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("""
            • You create a team and transfer your personal account into a team account
            • As the team owner you can invite and remove team members and  manage team settings
            • This change is permanent and irrevocable
            """)
            Text("Password")
                .font(.caption)
            TextField("", text: $password)
                .textFieldStyle(.roundedBorder)
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                HStack() {
                    Button(action: {
                        migrationConfirmed.toggle()
                    }, label: {
                        if migrationConfirmed {
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: "square")
                                .font(.system(size: 24))
                                .backgroundStyle(.gray)
                        }
                    })
                    .buttonStyle(.plain)
                    Text("I understand that this migration from Personal to Team is permanent and cannot be undone.")
                        .font(.caption)
                }
                HStack() {
                    Button(action: {
                        termsAccepted.toggle()
                    }, label: {
                        if termsAccepted {
                            Image(systemName: "checkmark.square.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: "square")
                                .font(.system(size: 24))
                                .backgroundStyle(.gray)
                        }
                    })
                    .buttonStyle(.plain)
                    Text("Accept our [Terms & Conditions](https://wire.com/en/terms-of-use-business) and [Privacy Policy](https://wire.com/en/privacy-policy).
")
                        .font(.caption)
                }
            }
            VStack(alignment: .leading) {
                BackButton(
                    action: { },
                    title: "Back"
                )
                CallToActionButton(
                    title: "Continue",
                    action: { }
                )
            }
        }
    }
}
