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
import UIKit
import WireDesign

/// A view that contains another `content` view.
/// If `isBubble` is set to `true`, it will look like a chat bubble containing `content`.
/// Otherwise it will be an invisible wrapper for `content`.
/// Set `bubbleStyle` to change the color of the bubble.
final class ConversationMessageContainerView: UIView {
    let content: UIView

    static let bubbleCornerRadius: CGFloat = 16

    static let bubbleEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 12, right: 12)

    enum BubbleStyle {
        case ownMessage(userColor: UIColor)
        case otherMessage
    }

    var bubbleStyle: BubbleStyle = .otherMessage {
        didSet {
            backgroundColor = if isBubble {
                switch bubbleStyle {
                case .otherMessage:
                    SemanticColors.ChatBubble.backgroundOtherMessage
                case let .ownMessage(userColor: color):
                    color
                }
            } else {
                .clear
            }
            setNeedsLayout()
        }
    }

    var isBubble: Bool = false {
        didSet {
            if isBubble {
                content.fitIn(view: self, insets: Self.bubbleEdgeInsets)
            } else {
                content.fitIn(view: self)
            }

            layer.cornerRadius = isBubble ? Self.bubbleCornerRadius : 0

            setNeedsLayout()
        }
    }

    init(content: UIView) {
        self.content = content

        super.init(frame: .zero)

        self.backgroundColor = .clear
        addSubview(content)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct ConversationMessageContainerView_Preview: UIViewRepresentable {
    var bubbleStyle: ConversationMessageContainerView.BubbleStyle
    var isBubble: Bool

    func makeUIView(context: Context) -> ConversationMessageContainerView {
        let label = UILabel()
        label.text = "This is a text message."
        label.textColor = switch bubbleStyle {
        case .ownMessage: .white
        case .otherMessage: .black
        }
        label.sizeToFit()
        let container = ConversationMessageContainerView(content: label)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isBubble = isBubble
        container.bubbleStyle = bubbleStyle
        return container
    }

    func updateUIView(_ view: ConversationMessageContainerView, context: Context) {}
}

#Preview {
    ScrollView {
        VStack {
            ConversationMessageContainerView_Preview(bubbleStyle: .otherMessage, isBubble: true)
        }
        .padding()
    }

    ScrollView {
        VStack {
            ConversationMessageContainerView_Preview(bubbleStyle: .ownMessage(userColor: .blue), isBubble: true)
        }
        .padding()
    }
}
