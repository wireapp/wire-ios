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
import WireDataModel
import WireDesign
import WireFoundation
import WireLinkPreview
import WireLogging
import WireUtilities

extension NSAttributedString {

    static var paragraphStyle: NSParagraphStyle = defaultParagraphStyle()

    static var previewParagraphStyle: NSParagraphStyle {
        defaultPreviewParagraphStyle()
    }

    static var style: DownStyle = defaultMarkdownStyle()

    static var previewStyle: DownStyle = previewMarkdownStyle()

    /// This method needs to be called as soon as the preferredContentSizeCategory is changed
    @objc
    static func invalidateParagraphStyle() {
        paragraphStyle = defaultParagraphStyle()
    }

    /// This method needs to be called as soon as the text color configuration is changed.
    @objc
    static func invalidateMarkdownStyle() {
        style = defaultMarkdownStyle()
        previewStyle = previewMarkdownStyle()
    }

    fileprivate static func defaultParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()

        paragraphStyle.minimumLineHeight = 22 * UIFont
            .wr_preferredContentSizeMultiplier(for: UIApplication.shared.preferredContentSizeCategory)
        paragraphStyle.paragraphSpacing = CGFloat.MessageCell.paragraphSpacing

        return paragraphStyle
    }

    fileprivate static func defaultPreviewParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()

        paragraphStyle.paragraphSpacing = 0

        return paragraphStyle
    }

    fileprivate static func previewMarkdownStyle() -> DownStyle {
        let style = DownStyle.preview

        style.baseFontColor = SemanticColors.Label.textDefault
        style.codeColor = style.baseFontColor
        style.h1Color = style.baseFontColor
        style.h2Color = style.baseFontColor
        style.h3Color = style.baseFontColor
        style.quoteColor = style.baseFontColor

        style.baseParagraphStyle = previewParagraphStyle
        style.listItemPrefixColor = style.baseFontColor.withAlphaComponent(0.64)

        return style
    }

    fileprivate static func defaultMarkdownStyle() -> DownStyle {
        let style = DownStyle.normal

        style.baseFont = UIFont.font(for: .body1)
        style.baseFontColor = ColorTheme.Backgrounds.onBackground
        style.baseParagraphStyle = paragraphStyle
        style.listItemPrefixColor = style.baseFontColor.withAlphaComponent(0.64)
        style.quoteColor = style.baseFontColor.withAlphaComponent(0.6)
        style.quoteParagraphStyle = paragraphStyle.indentedBy(points: 10)

        return style
    }

    static func formatForPreview(
        message: TextMessageData,
        inputMode: Bool,
        textColor: UIColor = ColorTheme.Backgrounds.onBackground,
        accentColor: AccentColor
    ) -> NSAttributedString {
        var plainText = message.messageText ?? ""

        // Substitute mentions with text markers
        let mentionTextObjects = plainText.replaceMentionsWithTextMarkers(mentions: message.mentions)

        // Perform markdown parsing
        let markdownText = NSMutableAttributedString.markdown(from: plainText, style: previewStyle)

        // Reply previews are line-limited (`maximumNumberOfLines = 4`), and the layout
        // blanks `markdown(from:)` inserts between list items would each consume one
        // of those visible slots. Drop them so the preview shows 4 real items, not
        // 2 items + 2 blanks.
        markdownText.stripLayoutBlankLines()

        // Highlight mentions using previously inserted text markers
        markdownText
            .highlight(
                mentions: mentionTextObjects,
                paragraphStyle: nil,
                accentColor: accentColor
            )

        // Remove trailing link if we show a link preview
        let links = markdownText.links()

        // Do emoji substition (but not inside link or mentions)
        let linkAttachmentRanges = links.compactMap { Range<Int>($0.range) }
        let mentionRanges = mentionTextObjects.compactMap { $0.range(in: markdownText.string as String) }
        markdownText.replaceEmoticons(excluding: linkAttachmentRanges + mentionRanges)
        markdownText.removeTrailingWhitespace()

        if !inputMode {
            markdownText.changeFontSizeIfMessageContainsOnlyEmoticons(to: 32)
        }

        markdownText.removeAttribute(.link, range: NSRange(location: 0, length: markdownText.length))
        markdownText.addAttribute(
            .foregroundColor,
            value: textColor,
            range: NSRange(location: 0, length: markdownText.length)
        )
        return markdownText
    }

    static func format(
        message: TextMessageData,
        isObfuscated: Bool,
        accentColor: AccentColor
    ) -> NSAttributedString {

        var plainText = message.messageText ?? ""

        guard !isObfuscated else {
            let color: UIColor = accentColor.uiColor
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "RedactedScript-Regular", size: 18)!,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            return NSAttributedString(string: plainText, attributes: attributes)
        }

        // Substitute mentions with text markers
        let mentionTextObjects = plainText.replaceMentionsWithTextMarkers(mentions: message.mentions)

        // Perform markdown parsing
        let markdownText = NSMutableAttributedString.markdown(from: plainText, style: style)

        // Highlight mentions using previously inserted text markers
        markdownText.highlight(mentions: mentionTextObjects, accentColor: accentColor)

        // Remove trailing link if we show a link preview
        if let linkPreview = message.linkPreview {
            markdownText.removeTrailingLink(for: linkPreview)
        }

        // Do emoji substition (but not inside link or mentions)
        let links = markdownText.links()
        let linkAttachmentRanges = links.compactMap { Range<Int>($0.range) }
        let mentionRanges = mentionTextObjects.compactMap { $0.range(in: markdownText.string as String) }
        let codeBlockRanges = markdownText.ranges(of: .code).compactMap { Range<Int>($0) }
        markdownText.replaceEmoticons(excluding: linkAttachmentRanges + mentionRanges + codeBlockRanges)

        markdownText.removeTrailingWhitespace()
        markdownText.changeFontSizeIfMessageContainsOnlyEmoticons()

        return markdownText
    }

    func links() -> [URLWithRange] {
        NSDataDetector.linkDetector?.detectLinksAndRanges(in: string, excluding: []) ?? []
    }

}

extension NSMutableAttributedString {

    func replaceEmoticons(excluding excludedRanges: [Range<Int>]) {
        beginEditing(); defer { endEditing() }

        let allowedIndexSet = IndexSet(integersIn: Range<Int>(wholeRange)!, excluding: excludedRanges)

        // Reverse the order of replacing, if we start replace from the beginning, the string may be shorten and other
        // ranges may be invalid.
        for range in allowedIndexSet.rangeView.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            let convertedRange = NSRange(location: range.lowerBound, length: range.upperBound - range.lowerBound)
            mutableString.resolveEmoticonShortcuts(in: convertedRange)
        }
    }

    func changeFontSizeIfMessageContainsOnlyEmoticons(to fontSize: CGFloat = 40) {
        if (string as String).containsOnlyEmojiWithSpaces {
            setAttributes([.font: UIFont.systemFont(ofSize: fontSize)], range: wholeRange)
        }
    }

    func removeTrailingWhitespace() {
        let trailingWhitespaceRange = mutableString.rangeOfCharacter(
            from: .whitespacesAndNewlines,
            options: [.anchored, .backwards]
        )

        if trailingWhitespaceRange.location != NSNotFound {
            mutableString.deleteCharacters(in: trailingWhitespaceRange)
        }
    }

    /// Remove the 1pt-tall blank-line characters that
    /// `NSAttributedString.insertEmptyLinesAtParagraphBreaks` inserts between markdown
    /// list items. Reply-preview cells limit the text container to a fixed line count,
    /// where those layout blanks would otherwise eat visible rows.
    func stripLayoutBlankLines() {
        let nsString = mutableString as NSString
        var indicesToRemove: [Int] = []
        for i in 0 ..< length where nsString.character(at: i) == 0x0A {
            if let ps = attribute(.paragraphStyle, at: i, effectiveRange: nil) as? NSParagraphStyle,
               ps.minimumLineHeight == 1, ps.maximumLineHeight == 1 {
                indicesToRemove.append(i)
            }
        }
        for index in indicesToRemove.reversed() {
            deleteCharacters(in: NSRange(location: index, length: 1))
        }
    }

    func removeTrailingLink(for linkPreview: LinkMetadata) {
        let text = string

        guard
            let linkPreviewRange = text.range(
                of: linkPreview.originalURLString,
                options: .backwards,
                range: nil,
                locale: nil
            ),
            linkPreviewRange.upperBound == text.endIndex
        else {
            return
        }

        mutableString.replaceCharacters(in: NSRange(linkPreviewRange, in: text), with: "")
    }

}

private extension String {

    mutating func replaceMentionsWithTextMarkers(mentions: [Mention]) -> [TextMarker<Mention>] {
        mentions.sorted(by: {
            $0.range.location > $1.range.location
        }).compactMap { mention -> TextMarker<Mention>? in
            // All mentions are expected to have a @ prefix and the range
            // of the mention should include this prefix (and not just the
            // name). Eg "Hello @bob" should have a mention range of
            // NSRange(location: 6, length: 4). If it doesn't, it will
            // be rendered incorrectly.
            //
            // But we suspect in some cases the sender might be only
            // specifying a mention range that covers the name and not
            // the @ prefix (i.e NSRange(location: 7, length: 3)).
            //
            // To handle this case, we check if the range includes the @
            // and if it doesn't adjust the range so that it does.
            var adjustedRange = mention.range

            if adjustedRange.location > 0, adjustedRange.location < utf16.count {
                let utf16View = self.utf16
                let charIndex = utf16View.index(utf16View.startIndex, offsetBy: adjustedRange.location)

                if charIndex < utf16View.endIndex {
                    let charAtLocation = utf16View[charIndex]

                    // If the range doesn't start with '@', check if the character before does
                    if charAtLocation != 64 { // '@' in UTF-16
                        let prevIndex = utf16View.index(before: charIndex)
                        if prevIndex >= utf16View.startIndex, utf16View[prevIndex] == 64 {
                            // Adjust range to include the '@'
                            adjustedRange.location -= 1
                            adjustedRange.length += 1
                        }
                    }
                }
            }

            guard let range = Range(adjustedRange, in: self) else { return nil }
            let name = String(self[range])

            // Final validation: ensure the extracted name starts with '@'
            guard name.hasPrefix("@") else {
                WireLogger.messaging.error("Mention range does not start with '@': \(mention.range), text: '\(name)'")
                return nil
            }

            // Create a corrected mention with the adjusted range
            let correctedMention = Mention(range: adjustedRange, user: mention.user)

            // Strip the '@' from the name since the mention rendering code adds it back
            let nameWithoutAt = name.hasPrefix("@") ? String(name.dropFirst()) : name

            let textObject = TextMarker<Mention>(correctedMention, replacementText: nameWithoutAt)
            replaceSubrange(range, with: textObject.token)
            return textObject
        }
    }

}

private extension IndexSet {

    init(integersIn range: Range<IndexSet.Element>, excluding: [Range<IndexSet.Element>]) {

        var excludedIndexSet = IndexSet()
        var includedIndexSet = IndexSet()

        excluding.forEach { excludedIndexSet.insert(integersIn: $0) }
        includedIndexSet.insert(integersIn: range)

        self = includedIndexSet.subtracting(excludedIndexSet)
    }

}

// extension from Down
private extension NSParagraphStyle {

    func indentedBy(points: CGFloat) -> NSParagraphStyle {
        let copy = mutableCopy() as! NSMutableParagraphStyle
        copy.firstLineHeadIndent += points
        copy.headIndent += points
        copy.tabStops = copy.tabStops.map {
            NSTextTab(textAlignment: $0.alignment, location: $0.location + points)
        }
        return copy as NSParagraphStyle
    }

}
