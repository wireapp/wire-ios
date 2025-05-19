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

public class TextMessageViewModel: ObservableObject, Identifiable, ConversationCellModelProtocol {

    public let id = UUID()

    public typealias ContentView = TextMessageView

    @ObservedObject var senderViewModelWrapper: MessageSenderViewModelWrapper
    @ObservedObject var statusViewModel: MessageStatusViewModel

    public func buildView() -> ContentView {
        ContentView(model: self)
    }

//    public var id: AnyHashable { self }

//    private var timer: AnyCancellable?

//    public var significantChangeSubject = PassthroughSubject<Void, Never>()

    @Published var text: String

    public init(
        text: String,
        senderViewModelWrapper: MessageSenderViewModelWrapper?,
        statusViewModel: MessageStatusViewModel
    ) {
        self.text = text // TODO: format
        self.senderViewModelWrapper = senderViewModelWrapper!
        self.statusViewModel = statusViewModel
    }

}
