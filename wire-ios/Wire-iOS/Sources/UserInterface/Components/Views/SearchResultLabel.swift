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
    // MARK: Lifecycle

    convenience init(instance: SearchResultLabel) {
        self.init()
        self.font = instance.font
        self.textColor = instance.textColor
        self.resultText = instance.resultText
        self.queries = instance.queries
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.lineBreakMode = .byTruncatingTail
        self.textColor = SemanticColors.Label.textDefault
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatal("init?(coder:) is not implemented")
    }

    // MARK: Internal

    var resultText: String? = .none
    var queries: [String] = []

    var estimatedMatchesCount = 0

    var isObfuscated = false {
        didSet {
            updateText()
        }
    }

    override var font: UIFont! {
        didSet {
            updateText()
        }
    }

    override var textColor: UIColor! {
        didSet {
            updateText()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !bounds.equalTo(previousLayoutBounds) else {
            return
        }

        previousLayoutBounds = bounds

        updateText()
    }

    func configure(with text: String, queries: [String]) {
        guard let font,
              let color = textColor else {
            self.attributedText = .none
            return
        }

        resultText = text
        self.queries = queries

        let currentFont = isObfuscated ? redactedFont.withSize(font.pointSize) : font
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [.font: currentFont, .foregroundColor: color]
        )

        let currentRange = text.range(
            of: queries,
            options: [.diacriticInsensitive, .caseInsensitive]
        )

        if let range = currentRange {
            let nsRange = text.nsRange(from: range)

            let highlightedAttributes = [
                NSAttributedString.Key.font: font,
                .backgroundColor: UIColor.accentDarken,
            ]

            if fits(attributedText: attributedText, fromRange: nsRange) {
                self.attributedText = attributedText.highlightingAppearances(
                    of: queries,
                    with: highlightedAttributes,
                    upToWidth: bounds.width,
                    totalMatches: &estimatedMatchesCount
                )
            } else {
                self.attributedText = attributedText.cutAndPrefixedWithEllipsis(
                    from: nsRange.location,
                    fittingIntoWidth: bounds.width
                )
                .highlightingAppearances(
                    of: queries,
                    with: highlightedAttributes,
                    upToWidth: bounds.width,
                    totalMatches: &estimatedMatchesCount
                )
            }
        } else {
            self.attributedText = attributedText
        }
    }

    // MARK: Fileprivate

    fileprivate var previousLayoutBounds: CGRect = .zero

    fileprivate func fits(attributedText: NSAttributedString, fromRange: NSRange) -> Bool {
        let textCutToRange = attributedText.attributedSubstring(from: NSRange(
            location: 0,
            length: fromRange.location + fromRange
                .length
        ))

        let labelSize = textCutToRange.layoutSize()

        return labelSize.height <= bounds.height && labelSize.width <= bounds.width
    }

    // MARK: Private

    private let redactedFont = UIFont(name: "RedactedScript-Regular", size: 16)!

    private func updateText() {
        guard let text = resultText else {
            attributedText = .none
            return
        }
        configure(with: text, queries: queries)
    }
}
