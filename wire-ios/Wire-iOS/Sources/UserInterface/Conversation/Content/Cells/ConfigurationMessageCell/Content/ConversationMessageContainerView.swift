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

import UIKit
import SwiftUI

/// A view that contains a conversation message view.
/// If `isBubble` is set to `true`, it will look like a chat bubble.
/// Otherwise it will be an invisible wrapper for the message.
final class ConversationMessageContainerView: UIView {
    let content: UIView
    
    static let bubbleInnerPadding: CGFloat = 8
    
    var isFromSelfUser: Bool = false {
        didSet {
            content.backgroundColor = isFromSelfUser ? .blue.withAlphaComponent(0.3) : .red.withAlphaComponent(0.3)
            setNeedsLayout()
        }
    }
    
    var isBubble: Bool = false {
        didSet {
            if isBubble {
                self.backgroundColor = .yellow //TODO: remove
                content.backgroundColor = .red.withAlphaComponent(0.3) //TODO: remove
                
                let padding = Self.bubbleInnerPadding
                content.fitIn(view: self, insets: .init(top: padding, left: padding, bottom: padding, right: padding))
            } else {
                self.backgroundColor = .clear //TODO: remove
                content.fitIn(view: self)
            }
            
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
    var isFromSelfUser: Bool
    var isBubble: Bool
    
    func makeUIView(context: Context) -> ConversationMessageContainerView {
        let label = UILabel()
        label.text = "This is a text message."
        label.sizeToFit()
        let container = ConversationMessageContainerView(content: label)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isBubble = isBubble
        container.isFromSelfUser = isFromSelfUser
        return container
    }
    
    func updateUIView(_ view: ConversationMessageContainerView, context: Context) {}
}

#Preview {
    ScrollView {
        VStack {
            ConversationMessageContainerView_Preview(isFromSelfUser: false, isBubble: true)
        }
        .padding()
    }
    
    ScrollView {
        VStack {
            ConversationMessageContainerView_Preview(isFromSelfUser: true, isBubble: true)
        }
        .padding()
    }
}
