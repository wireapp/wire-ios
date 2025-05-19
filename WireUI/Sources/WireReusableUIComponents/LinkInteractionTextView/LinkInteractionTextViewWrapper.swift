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
import Foundation
import WireFoundation

public struct LinkInteractionTextViewWrapper: UIViewRepresentable {
    
    let text: NSAttributedString
    let accentColor: AccentColor
    let shouldDetectTypes: Bool
    
    public init(text: NSAttributedString, accentColor: AccentColor, shouldDetectTypes: Bool) {
        self.text = text
        self.accentColor = accentColor
        self.shouldDetectTypes = shouldDetectTypes
    }
    
    public func makeUIView(context: Context) -> LinkInteractionTextView {
        let view = LinkInteractionTextView()
        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets.zero
        view.textContainer.lineFragmentPadding = 0
        view.isUserInteractionEnabled = false
        view.accessibilityIdentifier = "Message"
        view.accessibilityElementsHidden = false
        if shouldDetectTypes {
            view.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
            view.linkTextAttributes = [.foregroundColor: accentColor.uiColor]
        }
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        
        view.textContainer.maximumNumberOfLines = 3
        view.isScrollEnabled = false
        view.textContainer.lineBreakMode = .byTruncatingTail
        return view
    }
    
    public func updateUIView(_ uiView: LinkInteractionTextView, context: Context) {
        if uiView.attributedText != text {
            uiView.attributedText = text
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: LinkInteractionTextViewWrapper

        init(_ parent: LinkInteractionTextViewWrapper) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
//            parent.text = textView.text
        }
    }
}
