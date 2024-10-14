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

import UIKit
import WireFoundation

final class SubheadlineTextView: UITextView {

    init(
        attributedText: NSAttributedString,
        style: WireTextStyle,
        color: UIColor
    ) {
        super.init(frame: .zero, textContainer: nil)

        self.attributedText = attributedText
        self.textColor = color
        self.font = .font(for: style)
        configure()
    }

    private func configure() {
        adjustsFontForContentSizeCategory = true
        isScrollEnabled = false
        bounces = false
        backgroundColor = UIColor.clear
        linkTextAttributes = [
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// non-selectable textview
    override var selectedTextRange: UITextRange? {
        get { return nil }
        set { /* no-op */ }
    }

    // Prevent double-tap to select
    override var canBecomeFirstResponder: Bool {
        return false
    }

}
