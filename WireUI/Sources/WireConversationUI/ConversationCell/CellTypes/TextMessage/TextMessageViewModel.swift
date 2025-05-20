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

import Combine
import Foundation
import SwiftUI
import WireDesign
import WireFoundation
import WireReusableUIComponents

public class TextMessageViewModel: ObservableObject, Identifiable, ConversationCellModelProtocol {

    public let id = UUID()

    public typealias ContentView = TextMessageView
    
    @ObservedObject var senderViewModelWrapper: MessageSenderViewModelWrapper
    @ObservedObject var statusViewModel: MessageStatusViewModel

    public var onLinkTapped: ((URL) -> Bool)?

    @Published var text: NSAttributedString
    let accentColor: AccentColor

    public init(
        text: String,
        accentColor: AccentColor,
        isObfuscated: Bool,
        mentions: [MentionModel],
        senderViewModelWrapper: MessageSenderViewModelWrapper?,
        statusViewModel: MessageStatusViewModel
    ) {
        self.text = Self
            .format(
                text,
                isObfuscated: isObfuscated,
                accentColor: accentColor,
                mentions: mentions
            )
        self.accentColor = accentColor
        self.senderViewModelWrapper = senderViewModelWrapper!
        self.statusViewModel = statusViewModel
    }
    
    static func format(
        _ text: String,
        isObfuscated: Bool,
        accentColor: AccentColor,
        mentions: [MentionModel]
    ) -> NSAttributedString {
        NSAttributedString.format(
            text: text,
            isObfuscated: isObfuscated,
            accentColor: accentColor,
            mentions: mentions
        )

    }

}
