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
    let width: CGFloat
    
    public init(
        text: NSAttributedString,
        accentColor: AccentColor,
        shouldDetectTypes: Bool,
        width: CGFloat
    ) {
        self.text = text
        self.accentColor = accentColor
        self.shouldDetectTypes = shouldDetectTypes
        self.width = width
    }
    
    public func makeUIView(context: Context) -> LinkInteractionTextView {
        let view = LinkInteractionTextView()
        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0
        view.textContainer.lineBreakMode = .byWordWrapping
        view.isUserInteractionEnabled = false
        view.accessibilityIdentifier = "Message"
        view.accessibilityElementsHidden = false

        if shouldDetectTypes {
            view.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
            view.linkTextAttributes = [.foregroundColor: accentColor.uiColor]
        }

        return view
    }
    
    public func updateUIView(_ uiView: LinkInteractionTextView, context: Context) {
        uiView.setFixedWidth(width)

        if uiView.attributedText?.string != text.string {
            uiView.attributedText = text
        }
        
        uiView.layoutIfNeeded()
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
