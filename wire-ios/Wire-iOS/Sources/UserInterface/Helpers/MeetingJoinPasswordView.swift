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

import SwiftUI
import WireDesign

struct MeetingJoinPasswordView: View {

    private typealias Strings = L10n.Localizable.Join.Meeting.Alert
    private typealias ConversationStrings = L10n.Localizable.Join.Group.Conversation.Alert

    @State private var password = ""

    let incorrectPassword: Bool
    let completion: (String?) -> Void

    var errorMessage: String? {
        guard incorrectPassword else { return nil }
        return L10n.Localizable.UrlAction.JoinConversation.Error.Alert.InvalidPassword.message
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(Strings.message)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 8) {
                        SecureField(Strings.Textfield.placeholder, text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .onSubmit(join)
                            .accessibilityIdentifier("meetingJoinPassword")

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(ColorTheme.Base.error.color)
                                .accessibilityIdentifier("meetingJoinPasswordError")
                        }
                    }

                    Button(Strings.JoinAction.title, action: join)
                        .wireButtonStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .disabled(password.isEmpty)
                        .accessibilityIdentifier("joinMeetingWithPassword")

                    Link(
                        ConversationStrings.LearnMoreAction.title,
                        destination: WireURLs.shared.meetingGuestLinksInfoURL
                    )
                    .accessibilityIdentifier("meetingJoinPasswordHelp")
                }
                .padding()
            }
            .background(ColorTheme.Backgrounds.background.color)
            .navigationTitle(L10n.Localizable.Registration.Signin.Alert.PasswordNeeded.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Localizable.General.cancel) { completion(nil) }
                        .accessibilityIdentifier("cancelMeetingJoinPassword")
                }
            }
        }
    }

    private func join() {
        guard !password.isEmpty else { return }
        completion(password)
    }
}
