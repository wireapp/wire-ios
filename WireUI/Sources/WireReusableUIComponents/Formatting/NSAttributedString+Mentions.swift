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

import Foundation
import UIKit
import WireFoundation
import WireDesign

//private let log = ZMSLog(tag: "Mentions")

public struct MentionModel: Equatable {
    public static func == (lhs: MentionModel, rhs: MentionModel) -> Bool {
        lhs.range == rhs.range &&
        lhs.isSelfUser == rhs.isSelfUser &&
        lhs.object === rhs.object
    }


    public let range: NSRange
    public let isSelfUser: Bool
    public let object: AnyObject
    
    public init(range: NSRange, isSelfUser: Bool, object: AnyObject) {
        self.range = range
        self.isSelfUser = isSelfUser
        self.object = object
    }

    public static let mentionScheme = "wire-mention"

    public var link: URL {
        URL(string: "\(MentionModel.mentionScheme)://location/\(range.location)")!
    }

    public var location: Int {
        range.location
    }
}

public extension URL {

    var isMention: Bool {
        scheme == MentionModel.mentionScheme
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
        isSelfUser: Bool,
        name: String,
        link: URL,
        accentColor: AccentColor,
        suggestedAttributes: [NSAttributedString.Key: Any] = [:]
    ) -> NSAttributedString {
        let color: UIColor = accentColor.uiColor
        let backgroundColor: UIColor = if isSelfUser {
            .lowAccentColorForUsernameMention(accentColor: accentColor)
        } else {
            .clear
        }

        let suggestedFont = suggestedAttributes[.font] as? UIFont ?? UIFont.normalMediumFont
        let atFont: UIFont = suggestedFont.withSize(suggestedFont.pointSize - 2).withWeight(.light)
        let mentionFont = suggestedFont.isBold ? suggestedFont : suggestedFont.withWeight(.semibold)
        let paragraphStyle = suggestedAttributes[.paragraphStyle] ?? NSParagraphStyle.default

        var atAttributes: [NSAttributedString.Key: Any] = [
            .font: atFont,
            .foregroundColor: color,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle
        ]

        if !isSelfUser {
            atAttributes[NSAttributedString.Key.link] = link as NSObject
        }

        let atString = "@" && atAttributes

        var mentionAttributes: [NSAttributedString.Key: Any] = [
            .font: mentionFont,
            .foregroundColor: color,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle
        ]

        if !isSelfUser {
            mentionAttributes[NSAttributedString.Key.link] = link as NSObject
        }

        let mentionText = name && mentionAttributes

        return atString + mentionText
    }

    public func highlight(
        mentions: [TextMarker<MentionModel>],
        paragraphStyle: NSParagraphStyle? = NSAttributedString.paragraphStyle,
        accentColor: AccentColor
    ) {

        mentions.forEach { textObject in
            let mentionRange = mutableString.range(of: textObject.token)

            guard mentionRange.location != NSNotFound else {
                // TODO: add log
//                log.error("Cannot process mention: \(textObject)")
                return
            }

            var attributes = self.attributes(at: mentionRange.location, effectiveRange: nil)
            attributes[.paragraphStyle] = paragraphStyle
            let replacementString = NSMutableAttributedString.mention(
                isSelfUser: textObject.value.isSelfUser,
                name: textObject.replacementText,
                link: textObject.value.link,
                accentColor: accentColor,
                suggestedAttributes: attributes
            )

            self.replaceCharacters(in: mentionRange, with: replacementString)
        }
    }
}

extension UIColor {
    class func lowAccentColorForUsernameMention(accentColor: AccentColor) -> UIColor {
        switch accentColor {
        case .blue:
            SemanticColors.View.backgroundBlueUsernameMention
        case .red:
            SemanticColors.View.backgroundRedUsernameMention
        case .green:
            SemanticColors.View.backgroundGreenUsernameMention
        case .amber:
            SemanticColors.View.backgroundAmberUsernameMention
        case .turquoise:
            SemanticColors.View.backgroundTurqoiseUsernameMention
        case .purple:
            SemanticColors.View.backgroundPurpleUsernameMention
        }
    }
}
