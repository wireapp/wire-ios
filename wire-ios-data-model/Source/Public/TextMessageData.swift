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

import WireLinkPreview

@objc(ZMTextMessageData)
public protocol TextMessageData: NSObjectProtocol {

    var messageText: String? { get }
    var linkPreview: LinkMetadata? { get }
    var mentions: [Mention] { get }
    var quoteMessage: ZMConversationMessage? { get }

    /// `true` if the link preview will have an image.
    var linkPreviewHasImage: Bool { get }

    /// Unique identifier for link preview image.
    var linkPreviewImageCacheKey: String? { get }

    /// `true` if the user replied to her/his own message.
    var isQuotingSelf: Bool { get }

    /// `true` if the message has a quote.
    var hasQuote: Bool { get }

    /// Fetch linkpreview image data from disk on the given queue.
    @objc(fetchLinkPreviewImageDataWithQueue:completionHandler:)
    func fetchLinkPreviewImageData(
        queue: DispatchQueue,
        completionHandler: @escaping (_ imageData: Data?) -> Void
    )

    /// Request link preview image to be downloaded
    func requestLinkPreviewImageDownload()

    /// Edit the text content
    func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool)
}
