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

import Down
import UIKit

// extension from Down
private extension NSAttributedString.Key {
    /// The key for Markdown identification in an NSAttributedString.
    static let markdown = NSAttributedString.Key("MarkdownIDAttributeName")
}

/// Draws markdown-specific backgrounds:
/// - A vertical accent bar to the left of blockquote ranges.
/// - A flat background behind code ranges (inline and block).
final class BlockquoteLayoutManager: NSLayoutManager {

    /// Color of the blockquote accent bar. Update when the bubble style changes.
    var barColor: UIColor = .gray

    /// Background color drawn behind code ranges. Update when the bubble style changes.
    var codeBackgroundColor: UIColor = .init(white: 0.5, alpha: 0.15)

    private let barWidth: CGFloat = 2
    private let barLeadingOffset: CGFloat = 2

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        drawCodeBackgrounds(forGlyphRange: glyphsToShow, at: origin)
        drawBlockquoteBars(forGlyphRange: glyphsToShow, at: origin)
    }

    // MARK: - Code block backgrounds

    private func drawCodeBackgrounds(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage, let textContainer = textContainers.first else { return }

        let characterRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        codeBackgroundColor.setFill()

        textStorage.enumerateAttribute(.markdown, in: characterRange, options: []) { [weak self] value, range, _ in
            guard let self,
                  let markdown = value as? Markdown,
                  markdown.contains(.code)
            else { return }

            // Fill only the rects that actually enclose the code glyphs so that
            // inline code is highlighted just behind its text, rather than across
            // the full line width.
            let codeGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            enumerateEnclosingRects(
                forGlyphRange: codeGlyphRange,
                withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0),
                in: textContainer
            ) { rect, _ in
                UIRectFill(rect.offsetBy(dx: origin.x, dy: origin.y))
            }
        }
    }

    // MARK: - Blockquote bars

    private func drawBlockquoteBars(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage else { return }

        let characterRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        barColor.setFill()

        textStorage.enumerateAttribute(.markdown, in: characterRange, options: []) { [weak self] value, range, _ in
            guard let self,
                  let markdown = value as? Markdown,
                  markdown.contains(.quote),
                  let (minY, maxY) = yRange(forGlyphRange: glyphRange(
                      forCharacterRange: range,
                      actualCharacterRange: nil
                  ))
            else { return }

            UIRectFill(CGRect(
                x: origin.x + barLeadingOffset,
                y: origin.y + minY,
                width: barWidth,
                height: maxY - minY
            ))
        }
    }

    private func yRange(forGlyphRange glyphRange: NSRange) -> (CGFloat, CGFloat)? {
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        enumerateLineFragments(forGlyphRange: glyphRange) { rect, _, _, _, _ in
            minY = min(minY, rect.minY)
            maxY = max(maxY, rect.maxY)
        }
        return minY < maxY ? (minY, maxY) : nil
    }
}
