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
import SwiftProtobuf
import WireProtos

private let redactedValue = "<redacted>"

// MARK: - Text

extension Text {
    fileprivate func sanitize() -> Text {
        var text = self
        text.content = redactedValue
        text.linkPreview = text.linkPreview.map { $0.sanitize() }
        return text
    }
}

// MARK: - LinkPreview

extension LinkPreview {
    fileprivate func sanitize() -> LinkPreview {
        LinkPreview(
            withOriginalURL: redactedValue,
            permanentURL: redactedValue,
            offset: urlOffset,
            title: redactedValue,
            summary: redactedValue,
            imageAsset: image,
            article: article.sanitize(),
            tweet: nil
        )
    }
}

// MARK: - Article

extension Article {
    fileprivate func sanitize() -> Article {
        Article.with {
            $0.title = redactedValue
            $0.permanentURL = redactedValue
            $0.summary = redactedValue
        }
    }
}

// MARK: - GenericMessage + CustomStringConvertible

extension GenericMessage: CustomStringConvertible {
    public var description: String {
        var message = self
        guard let content else {
            return ""
        }
        switch content {
        case .text:
            message.text = text.sanitize()
        case .edited:
            message.edited.text = edited.text.sanitize()
        default:
            break
        }
        message.messageID = messageID.redactedAndTruncated()
        message.reaction.emoji = reaction.emoji.redacted
        return message.debugDescription
    }
}

// MARK: - GenericMessage + SafeForLoggingStringConvertible

extension GenericMessage: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        "[\(safeTypeForLoggingDescription) \(safeIdForLoggingDescription)]"
    }

    public var safeIdForLoggingDescription: String {
        UUID(uuidString: messageID)?.safeForLoggingDescription ?? "<nil>"
    }

    public var safeTypeForLoggingDescription: String {
        content?.safeForLoggingDescription ?? "unknown"
    }
}

// MARK: - GenericMessage.OneOf_Content + SafeForLoggingStringConvertible

extension GenericMessage.OneOf_Content: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        switch self {
        case .text:
            "text"

        case .image:
            "image"

        case .knock:
            "knock"

        case .lastRead:
            "lastRead"

        case .cleared:
            "cleared"

        case .external:
            "external"

        case .clientAction:
            "clientAction"

        case .calling:
            "calling"

        case .asset:
            "asset"

        case .hidden:
            "hidden"

        case .location:
            "location"

        case .deleted:
            "deleted"

        case .edited:
            "edited"

        case .confirmation:
            "confirmation"

        case .reaction:
            "reaction"

        case .ephemeral:
            "ephemeral"

        case .availability:
            "availability"

        case .composite:
            "composite"

        case .buttonAction:
            "buttonAction"

        case .buttonActionConfirmation:
            "buttonActionConfirmation"

        case .dataTransfer:
            "dataTransfer"
        }
    }
}
