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
import WireLinkPreview

public final class TextMessage: ZMMessage, TextMessageData {

    public var messageText: String? { fatalError("TODO") }

    public var linkPreview: LinkMetadata? { fatalError("TODO") }

    public var mentions: [Mention] { fatalError("TODO") }

    public var quoteMessage: (any ZMConversationMessage)? { fatalError("TODO") }

    public var linkPreviewHasImage: Bool { fatalError("TODO") }

    public var linkPreviewImageCacheKey: String? { fatalError("TODO") }

    public var isQuotingSelf: Bool { fatalError("TODO") }

    public var hasQuote: Bool { fatalError("TODO") }

    public func fetchLinkPreviewImageData(queue: DispatchQueue) async -> NSData? {
        fatalError("TODO")
    }

    public func requestLinkPreviewImageDownload() {
        fatalError("TODO")
    }

    public func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        fatalError("TODO")
    }
}
