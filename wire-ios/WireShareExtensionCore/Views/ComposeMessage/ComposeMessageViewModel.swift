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

import Foundation
import SwiftUI

@MainActor
protocol ComposeMessageViewModel {

    var conversation: Conversation { get }
    var shareItem: ShareItem { get }
    var messageText: String { get set }
    var canSend: Bool { get }

    func send()

}

@Observable
@MainActor
public final class ComposeMessageViewModelImpl: ComposeMessageViewModel {

    public let conversation: Conversation
    public let shareItem: ShareItem
    public var messageText: String = ""

    public var canSend: Bool {
        true
    }

    public init(
        conversation: Conversation,
        shareItem: ShareItem
    ) {
        self.conversation = conversation
        self.shareItem = shareItem
    }

    public func send() {
        print("Sending message to \(conversation.name): \(messageText)")
    }

}
