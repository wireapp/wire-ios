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

import AppIntents

@available(iOS 16, *)
struct SendQuickResponseIntent: AppIntent {

    static var title: LocalizedStringResource = "Send Quick Response"

    @Parameter(title: "Message")
    var message: String

    @Parameter(title: "Conversation")
    var conversation: ConversationEntity

    static var description = IntentDescription("Sends a quick response message to a specified recipient.")

    func perform() async throws -> some IntentResult {
        // Logic to send the message via Wire's messaging service
        // This will require Wire's API or internal messaging function to send the message

        print("Sending '\(message)' to \(conversation)")

        return .result()
    }
}
