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
import WireDesign
import WireSystem

final class SearchResultLabel: UILabel, Copyable {
    convenience init(instance: SearchResultLabel) {
        self.init()
        self.font = instance.font
        self.textColor = instance.textColor
        self.resultText = instance.resultText
        self.queries = instance.queries
    }

    var resultText: String? = .none
    var queries: [String] = []

    private let redactedFont = UIFont(name: "RedactedScript-Regular", size: 16)!

    var isObfuscated = false {
        didSet {
            self.updateText()
        }
    }

    override var font: UIFont! {
        didSet {
            self.updateText()
        }
    }

    override var textColor: UIColor! {
        didSet {
            self.updateText()
        }
    }

    var estimatedMatchesCount = 0

    fileprivate var previousLayoutBounds: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.lineBreakMode = .byTruncatingTail
        textColor = SemanticColors.Label.textDefault
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatal("init?(coder:) is not implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !self.bounds.equalTo(self.previousLayoutBounds) else {
            return
        }

        self.previousLayoutBounds = self.bounds

        self.updateText()
    }

    func configure(with text: String, queries: [String]) {
        guard let font = self.font,
              let color = self.textColor else {
            self.attributedText = .none
            return
        }

        self.resultText = text
        self.queries = queries

        let currentFont = isObfuscated ? redactedFont.withSize(font.pointSize) : font
        let attributedText = NSMutableAttributedString(string: text, attributes: [.font: currentFont, .foregroundColor: color])

        let currentRange = text.range(of: queries,
                                      options: [.diacriticInsensitive, .caseInsensitive])

        if let range = currentRange {
            let nsRange = text.nsRange(from: range)

            let highlightedAttributes = [NSAttributedString.Key.font: font,
                                         .backgroundColor: UIColor.accentDarken]

            if self.fits(attributedText: attributedText, fromRange: nsRange) {
                self.attributedText = attributedText.highlightingAppearances(of: queries,
                                                                             with: highlightedAttributes,
                                                                             upToWidth: self.bounds.width,
                                                                             totalMatches: &estimatedMatchesCount)
            } else {
                self.attributedText = attributedText.cutAndPrefixedWithEllipsis(from: nsRange.location, fittingIntoWidth: self.bounds.width)
                    .highlightingAppearances(of: queries,
                                             with: highlightedAttributes,
                                             upToWidth: self.bounds.width,
                                             totalMatches: &estimatedMatchesCount)
            }
        } else {
            self.attributedText = attributedText
        }
    }

    private func updateText() {
        guard let text = self.resultText else {
            self.attributedText = .none
            return
        }
        self.configure(with: text, queries: self.queries)
    }

    fileprivate func fits(attributedText: NSAttributedString, fromRange: NSRange) -> Bool {
        let textCutToRange = attributedText.attributedSubstring(from: NSRange(location: 0, length: fromRange.location + fromRange.length))

        let labelSize = textCutToRange.layoutSize()

        return labelSize.height <= self.bounds.height && labelSize.width <= self.bounds.width
    }
}
