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

@objc(ZMTextMessage) @objcMembers
final class TextMessage: ZMMessage, TextMessageData {

    override class func entityName() -> String {
        "TextMessage"
    }

    @NSManaged public var text: String?

    override var textMessageData: (any TextMessageData)? { self }

    var messageText: String? { text }

    var linkPreview: LinkMetadata? { .none }

    var mentions: [Mention] { [] }

    var quoteMessage: (any ZMConversationMessage)? { nil }

    var linkPreviewHasImage: Bool { false }

    var linkPreviewImageCacheKey: String? { nil }

    var isQuotingSelf: Bool { false }

    var hasQuote: Bool { false }

    override func shortDebugDescription() -> String {
        super.shortDebugDescription() + ", \(text ?? "<nil>")"
    }

    override class func createOrUpdate(
        from updateEvent: ZMUpdateEvent,
        in moc: NSManagedObjectContext,
        prefetchResult: ZMFetchRequestBatchResult?
    ) -> Self? {
        nil
    }

    func fetchLinkPreviewImageData(
        queue: DispatchQueue,
        completionHandler: @escaping (_ imageData: Data?) -> Void
    ) {
        completionHandler(nil)
    }

    func requestLinkPreviewImageDownload() {
        // no op
    }

    func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        // no op
    }
}

/*

 - (NSData *)linkPreviewImageData
 {
     return nil;
 }

 - (void)removeMessageClearingSender:(BOOL)clearingSender
 {
     self.text = nil;
     [super removeMessageClearingSender:clearingSender];
 }

 */
