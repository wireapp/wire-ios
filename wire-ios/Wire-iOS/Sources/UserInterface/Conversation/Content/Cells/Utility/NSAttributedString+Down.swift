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
import Foundation
import UIKit

extension NSAttributedString {

    @objc
    static func markdown(from text: String, style: DownStyle) -> NSMutableAttributedString {
        let down = Down(markdownString: text)
        let result: NSMutableAttributedString = if let attrStr = try? down.toAttributedString(using: style) {
            .init(attributedString: attrStr)
        } else {
            NSMutableAttributedString(string: text)
        }

        // Paragraph-break newlines emitted by Down carry an explicit paragraphStyle (with
        // paragraphSpacing > 0), whereas soft-break newlines carry no paragraphStyle at all.
        // Insert an actual blank-line newline after each paragraph break so that a double-
        // newline in the original text renders as a visible empty line.
        result.insertEmptyLinesAtParagraphBreaks()

        // There may now be two trailing newlines (paragraph break + blank line); remove both.
        // Track whether the last paragraph was a list item so we can re-append a tiny
        // buffer below — UITextView's intrinsic height drops the last list item otherwise.
        var trailedListItem = false
        while result.string.last == "\n" {
            if !trailedListItem,
               let ps = result.attribute(
                .paragraphStyle,
                at: result.length - 1,
                effectiveRange: nil
               ) as? NSParagraphStyle,
               ps.headIndent > 0 {
                trailedListItem = true
            }
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }

        // For lists, append a 1pt-tall trailing newline so the last item isn't clipped.
        // Without this, single-item lists (and the last item of any list) lose their content.
        if trailedListItem {
            let blankStyle = NSMutableParagraphStyle()
            blankStyle.minimumLineHeight = 1
            blankStyle.maximumLineHeight = 1
            blankStyle.paragraphSpacing = 0
            result.append(NSAttributedString(
                string: "\n",
                attributes: [.paragraphStyle: blankStyle as NSParagraphStyle]
            ))
        }

        guard !result.string.isEmpty else {
            return .init(string: text)
        }

        return result
    }
}

private extension NSMutableAttributedString {

    /// Inserts a blank-line newline after every paragraph-break newline.
    ///
    /// Down marks paragraph-break newlines with an explicit `.paragraphStyle` whose
    /// `paragraphSpacing > 0`.  Soft-break newlines have no paragraph style at all.
    /// By inserting a second `\n` (carrying only `minimumLineHeight`) we create a real
    /// empty line rather than relying on `paragraphSpacing`, which can be too subtle.
    func insertEmptyLinesAtParagraphBreaks() {
        // Collect the indices of paragraph-break newlines and whether each one belongs
        // to a list item (Down marks list-item terminators with headIndent > 0).
        var breakIndices = [(index: Int, isListItem: Bool)]()
        let nsString = string as NSString
        var i = 0
        while i < length {
            if nsString.character(at: i) == 0x0A,
               let ps = attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle,
               ps.paragraphSpacing > 0 {
                breakIndices.append((i, ps.headIndent > 0))
            }
            i += 1
        }

        // Process in reverse so earlier insertions don't shift later indices.
        for (breakIndex, isListItem) in breakIndices.reversed() {
            // Build the blank-line style:
            // - For regular paragraph breaks: full line height so a double-newline in the
            //   source renders as a visible empty line.
            // - For list-item terminators: a near-zero line height so list items pack
            //   tightly. We still insert a (collapsed) blank line because skipping it
            //   entirely breaks UITextView's height calculation for the last item.
            let existingStyle = attribute(.paragraphStyle, at: breakIndex, effectiveRange: nil) as? NSParagraphStyle
            let blankStyle = NSMutableParagraphStyle()
            blankStyle.minimumLineHeight = isListItem ? 1 : (existingStyle?.minimumLineHeight ?? 22)
            blankStyle.maximumLineHeight = isListItem ? 1 : 0
            blankStyle.paragraphSpacing = 0

            let blankLine = NSAttributedString(
                string: "\n",
                attributes: [.paragraphStyle: blankStyle as NSParagraphStyle]
            )
            insert(blankLine, at: breakIndex + 1)
        }
    }
}

extension NSAttributedString {

    /// Trim the NSAttributedString to given number of line limit and add an ellipsis at the end if necessary
    ///
    /// - Parameter numberOfLinesLimit: number of line reserved
    /// - Returns: the trimmed NSAttributedString. If not excess limit, return the original NSAttributedString
    func trimmedToNumberOfLines(numberOfLinesLimit: Int) -> NSAttributedString {
        // Trim the string to first four lines to prevent last line narrower spacing issue
        let lines = string.components(separatedBy: ["\n"])
        if lines.count > numberOfLinesLimit {
            let headLines = lines.prefix(numberOfLinesLimit).joined(separator: "\n")

            return attributedSubstring(from: NSRange(location: 0, length: headLines.count)) + String.ellipsis
        } else {
            return self
        }
    }
}
