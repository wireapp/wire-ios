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

import Foundation
import WireDataModel

private let log = ZMSLog(tag: "Mentions")

// MARK: - TextMarker

struct TextMarker<A> {
    // MARK: Lifecycle

    init(_ value: A, replacementText: String) {
        self.value = value
        self.replacementText = replacementText
        self.token = UUID().transportString()
    }

    // MARK: Internal

    let replacementText: String
    let token: String
    let value: A
}

extension TextMarker {
    func range(in string: String) -> Range<Int>? {
        Range((string as NSString).range(of: token))
    }
}

extension Mention {
    static let mentionScheme = "wire-mention"

    var link: URL {
        URL(string: "\(Mention.mentionScheme)://location/\(range.location)")!
    }

    var location: Int {
        range.location
    }
}

extension URL {
    var isMention: Bool {
        scheme == Mention.mentionScheme
    }

    var mentionLocation: Int {
        guard isMention, let indexString = pathComponents.last, let index = Int(indexString) else {
            return NSNotFound
        }

        return index
    }
}

extension NSMutableAttributedString {
    private static func mention(
        for user: UserType,
        name: String,
        link: URL,
        suggestedAttributes: [NSAttributedString.Key: Any] = [:]
    ) -> NSAttributedString {
        let color: UIColor
        let backgroundColor: UIColor

        if user.isSelfUser {
            color = .accent()
            backgroundColor = .lowAccentColorForUsernameMention()
        } else {
            color = .accent()
            backgroundColor = .clear
        }

        let suggestedFont = suggestedAttributes[.font] as? UIFont ?? UIFont.normalMediumFont
        let atFont: UIFont = suggestedFont.withSize(suggestedFont.pointSize - 2).withWeight(.light)
        let mentionFont = suggestedFont.isBold ? suggestedFont : suggestedFont.withWeight(.semibold)
        let paragraphStyle = suggestedAttributes[.paragraphStyle] ?? NSParagraphStyle.default

        var atAttributes: [NSAttributedString.Key: Any] = [
            .font: atFont,
            .foregroundColor: color,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle,
        ]

        if !user.isSelfUser {
            atAttributes[NSAttributedString.Key.link] = link as NSObject
        }

        let atString = "@" && atAttributes

        var mentionAttributes: [NSAttributedString.Key: Any] = [
            .font: mentionFont,
            .foregroundColor: color,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle,
        ]

        if !user.isSelfUser {
            mentionAttributes[NSAttributedString.Key.link] = link as NSObject
        }

        let mentionText = name && mentionAttributes

        return atString + mentionText
    }

    func highlight(
        mentions: [TextMarker<Mention>],
        paragraphStyle: NSParagraphStyle? = NSAttributedString.paragraphStyle
    ) {
        for textObject in mentions {
            let mentionRange = mutableString.range(of: textObject.token)

            guard mentionRange.location != NSNotFound else {
                log.error("Cannot process mention: \(textObject)")
                continue
            }

            var attributes = attributes(at: mentionRange.location, effectiveRange: nil)
            attributes[.paragraphStyle] = paragraphStyle
            let replacementString = NSMutableAttributedString.mention(
                for: textObject.value.user,
                name: textObject.replacementText,
                link: textObject.value.link,
                suggestedAttributes: attributes
            )

            replaceCharacters(in: mentionRange, with: replacementString)
        }
    }
}
