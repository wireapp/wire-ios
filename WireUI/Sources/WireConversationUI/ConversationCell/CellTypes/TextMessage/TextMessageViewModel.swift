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

    @ObservedObject var senderViewModel: MessageSenderViewModel
    @ObservedObject public var statusViewModel: MessageStatusViewModel

    public func buildView() -> ContentView {
        ContentView(model: self)
    }

//    public var id: AnyHashable { self }

//    private var timer: AnyCancellable?

//    public var significantChangeSubject = PassthroughSubject<Void, Never>()

    @Published var text: String

    public init(
        text: String,
        senderViewModel: MessageSenderViewModel?,
        statusViewModel: MessageStatusViewModel
    ) {
        self.text = text // TODO: format
        self.senderViewModel = senderViewModel!
        self.statusViewModel = statusViewModel
//        startRandomStateTimer()
    }

//    private func startRandomStateTimer() {
//        timer = Timer.publish(every: 1.0, on: .main, in: .common)
//            .autoconnect()
//            .sink { [weak self] _ in
//                guard let self else { return }
//                let (newText, lines) = self.randomMultilineText()
//                if lines >= 2 {
//                    self.significantChangeSubject.send(())
//                } else {
//                    self.text = newText
//                }
//            }
//    }

//    func randomMultilineText() -> (String, Int) {
//        let lines = [
//            "Hello!",
//            "This is a second line.",
//            "Here comes the third one."
//        ]
//
//        let numberOfLines = Int.random(in: 1...3)
//        return (lines.prefix(numberOfLines).joined(
//            separator: "\n"
//        ), numberOfLines)
//    }
//
//    deinit {
//        timer?.cancel()
//    }
}

extension ConversationCellModel {

//    static func timeDivider(
//        text: String,
//        isUnread: Bool
//    ) -> Self {
//        let model = TimeDividerModel(
//            text: text,
//            isUnreadIndicatorVisible: isUnread
//        )
//        return .timeDivider(model)
//    }
}
